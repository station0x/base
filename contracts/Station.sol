//SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";

interface IRegistry {
  function getAddressOf(string calldata) external view returns (address);
}

interface IStationHooks { 
  function onTransfer(address msgSender, address from, address to, uint256 tokenId) external returns (bool);
  function onSeize(address msgSender, address from, address to, uint256 tokenId) external returns (bool);
  function onDistribute(address msgSender, uint amount) external returns (bool);
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu) & Captain Isaac A.
/// @dev A mintable ERC20 token that allows anyone to pay and distribute a target token
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract Station is ERC721Enumerable, ERC721URIStorage {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
  using SafeERC20 for IERC20;
  
  IRegistry public registry;

  // With `magnitude`, we can properly distribute dividends even if the amount of received target is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(
    string memory _name,
    string memory _symbol,
    IRegistry _registry
  ) ERC721(_name, _symbol) {
    registry = _registry;
  }

  /// @notice Distributes target to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received target is greater than 0.
  /// About undistributed target tokens:
  ///   In each distribution, there is a small amount of target not distributed,
  ///     the magnified amount of which is
  ///     `(amount * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed target
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed target in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved target, so we don't do that.
  function distributeDividends(uint amount) public {
    require(totalSupply() > 0);
    require(amount > 0);
    IERC20 rewardToken = IERC20(registry.getAddressOf('rewardToken'));
    IStationHooks hooks = IStationHooks(registry.getAddressOf('stationHooks'));
    require(address(rewardToken) != address(0));
    require(hooks.onDistribute(msg.sender, amount));
    magnifiedDividendPerShare = magnifiedDividendPerShare.add(
      (amount).mul(magnitude) / totalSupply()
    );

    rewardToken.safeTransferFrom(msg.sender, address(this), amount);

    emit DividendsDistributed(msg.sender, amount);
  }

  /// @notice Withdraws the target distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn target is greater than 0.
  function withdrawDividend() public {
    IERC20 rewardToken = IERC20(registry.getAddressOf('rewardToken'));
    require(address(rewardToken) != address(0));
    uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[msg.sender] = withdrawnDividends[msg.sender].add(_withdrawableDividend);
      emit DividendWithdrawn(msg.sender, _withdrawableDividend);
      rewardToken.safeTransfer(msg.sender, _withdrawableDividend);
    }
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) internal view returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      IStationHooks hooks = IStationHooks(registry.getAddressOf('stationHooks'));
      require(hooks.onTransfer(msg.sender, from, to, tokenId));
      ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
      if(from == address(0)) {
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub( magnifiedDividendPerShare.toInt256Safe() );
      } else {
        int256 _magCorrection = magnifiedDividendPerShare.toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);          
      }
  }

  function mint(address to, uint256 tokenId, string memory _tokenURI, bytes memory _data) public {
    address manufacturer = registry.getAddressOf('manufacturerV1');
    require(msg.sender == manufacturer, "Do not call this function!");
    _safeMint(to, tokenId, _data);
    _setTokenURI(tokenId, _tokenURI);
  }

  function seize(address from, address to, uint256 tokenId) public {
    IStationHooks hooks = IStationHooks(registry.getAddressOf('stationHooks'));
    require(hooks.onSeize(msg.sender, from, to, tokenId));
    _transfer(from, to, tokenId);
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
    address manufacturer = registry.getAddressOf('manufacturerV1');
    require(msg.sender == manufacturer, "Do not call this function!");
    _setTokenURI(tokenId, _tokenURI);
  }

  
  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
    return ERC721Enumerable.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {}

  /// @dev This event MUST emit when target is distributed to token holders.
  /// @param from The address which sends target to this contract.
  /// @param weiAmount The amount of distributed target in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws target from this contract.
  /// @param weiAmount The amount of withdrawn target in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}