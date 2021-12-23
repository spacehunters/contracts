// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../eip20/BEP20.sol";
import "../utils/AccessControl.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/SafeMath.sol";
import "../eip20/SafeBEP20.sol";

contract TokenBase is BEP20, AccessControl, ReentrancyGuard {
    using SafeBEP20 for BEP20;
    using SafeMath for uint256;

    struct VestingType {
        string vestingName;
        uint256 tokenPrice;
        uint256 allocation;
        uint256 tgePercent;
        uint256 startTimeVesting;
        uint256 startTimeCliff;
        uint256 releaseRounds;
        uint256 daysPerRound;
        uint256 cliff;
        uint256 daysPerCliff;
        bool arbitrary;
    }

    struct VestingInfo {
        bool isActive;
        uint256 amount; // total amount
        uint256 claimedAmount; // claimed vest
    }

    mapping(uint256 => VestingType) private _vestingTypes;
    mapping(uint256 => uint256) private _projectSupplys;
    mapping(address => mapping(uint256 => VestingInfo)) private _vestingList;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ADMIN role required");
        _;
    }

    constructor(address multiSigAccount, string memory name, string memory symbol) BEP20(name, symbol) {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, multiSigAccount);
    }

    function getName(uint256 vestingType) public view returns (string memory) {
        return _vestingTypes[vestingType].vestingName;
    }
    function setName(uint256 vestingType, string memory vestingName) public onlyAdmin {
        _vestingTypes[vestingType].vestingName = vestingName;
    }

    function getTokenPrice(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].tokenPrice;
    }
    function setTokenPrice(uint256 vestingType, uint256 tokenPrice) public onlyAdmin {
        _vestingTypes[vestingType].tokenPrice = tokenPrice;
    }

    function getAllocation(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].allocation;
    }
    function setAllocation(uint256 vestingType, uint256 allocation) public onlyAdmin {
        _vestingTypes[vestingType].allocation = allocation;
    }

    function getTgePercent(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].tgePercent;
    }
    function setTgePercent(uint256 vestingType, uint256 tgePercent) public onlyAdmin {
        _vestingTypes[vestingType].tgePercent = tgePercent;
    }

    function getStartTimeVesting(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].startTimeVesting;
    }
    function setStartTimeVesting(uint256 vestingType, uint256 startTimeVesting) public onlyAdmin {
        _vestingTypes[vestingType].startTimeVesting = startTimeVesting;
    }

    function getStartTimeCliff(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].startTimeCliff;
    }
    function setStartTimeCliff(uint256 vestingType, uint256 startTimeCliff) public onlyAdmin {
        _vestingTypes[vestingType].startTimeCliff = startTimeCliff;
    }

    function getReleaseRound(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].releaseRounds;
    }
    function setReleaseRounds(uint256 vestingType, uint256 releaseRounds) public onlyAdmin {
        _vestingTypes[vestingType].releaseRounds = releaseRounds;
    }

    function getDaysPerRound(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].daysPerRound;
    }
    function setDaysPerRound(uint256 vestingType, uint256 daysPerRound) public onlyAdmin {
        _vestingTypes[vestingType].daysPerRound = daysPerRound;
    }

    function getCliff(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].cliff;
    }
    function setCliff(uint256 vestingType, uint256 cliff) public onlyAdmin {
        _vestingTypes[vestingType].cliff = cliff;
    }

    function getDaysPerCliff(uint256 vestingType) public view returns (uint256) {
        return _vestingTypes[vestingType].daysPerCliff;
    }
    function setDaysPerCliff(uint256 vestingType, uint256 daysPerCliff) public onlyAdmin {
        _vestingTypes[vestingType].daysPerCliff = daysPerCliff;
    }

    function getArbitrary(uint256 vestingType) public view returns (bool) {
        return _vestingTypes[vestingType].arbitrary;
    }
    function setArbitrary(uint256 vestingType, bool arbitrary) public onlyAdmin {
        _vestingTypes[vestingType].arbitrary = arbitrary;
    }

    function addVestingType(
        string memory vestingName,
        uint256 vestingType,
        uint256 tokenPrice,
        uint256 allocation,
        uint256 tgePercent,
        uint256 startTimeVesting,
        uint256 startTimeCliff,
        uint256 releaseRounds,
        uint256 daysPerRound,
        uint256 cliff,
        uint256 daysPerCliff,
        bool arbitrary
    ) public onlyAdmin {
        _vestingTypes[vestingType].vestingName = vestingName;
        _vestingTypes[vestingType].tokenPrice = tokenPrice;
        _vestingTypes[vestingType].allocation = allocation;
        _vestingTypes[vestingType].tgePercent = tgePercent;
        _vestingTypes[vestingType].startTimeVesting = startTimeVesting;
        _vestingTypes[vestingType].startTimeCliff = startTimeCliff;
        _vestingTypes[vestingType].releaseRounds = releaseRounds;
        _vestingTypes[vestingType].daysPerRound = daysPerRound;
        _vestingTypes[vestingType].cliff = cliff;
        _vestingTypes[vestingType].daysPerCliff = daysPerCliff;
        _vestingTypes[vestingType].arbitrary = arbitrary;
    }

    function addVestingTokenWithFund(
        address beneficiary,
        uint256 fund,
        uint256 vestingType
    ) external onlyAdmin {
        require(fund > 0, "Fund must be greater than 0");
        VestingType memory vestingTypeInfo = _vestingTypes[vestingType];
        require(vestingTypeInfo.startTimeVesting > 0, "No vesting time");

        uint256 amount = 0;
        uint256 tgeClaimed = 0;

        if(vestingTypeInfo.tokenPrice > 0) {
            amount = fund.mul(10000).div(vestingTypeInfo.tokenPrice);
        }
        if(vestingTypeInfo.tgePercent > 0) {
            tgeClaimed = amount.mul(vestingTypeInfo.tgePercent).div(10000);
        }

        _addVestingToken(beneficiary, amount, tgeClaimed, vestingType);
    }

    function addVestingToken(
        address beneficiary,
        uint256 vestingType
    ) external onlyAdmin {
        VestingType memory vestingTypeInfo = _vestingTypes[vestingType];
        require(vestingTypeInfo.startTimeVesting > 0, "No vesting time");

        uint256 amount = vestingTypeInfo.allocation;
        uint256 tgeClaimed = 0;

        if(vestingTypeInfo.tgePercent > 0) {
            tgeClaimed = amount.mul(vestingTypeInfo.tgePercent).div(10000);
        }

        _addVestingToken(beneficiary, amount, tgeClaimed, vestingType);
    } 

    function _addVestingToken(
        address beneficiary,
        uint256 amount,
        uint256 tgeClaimed,
        uint256 vestingType
    ) internal {
        require(beneficiary != address(0), "Zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(!_vestingList[beneficiary][vestingType].isActive, "Duplicate vesting address");   
        require(_projectSupplys[vestingType] + amount <= _vestingTypes[vestingType].allocation, "Max supply exceeded");

        VestingInfo memory info = VestingInfo(
            true,
            amount,
            tgeClaimed
        );
        _vestingList[beneficiary][vestingType] = info;
        
        if(tgeClaimed > 0) {
            _mint(beneficiary, tgeClaimed);
        }
        
        _projectSupplys[vestingType] = _projectSupplys[vestingType].add(amount);
    }

    function revokeVestingToken(address user, uint256 vestingType) external onlyAdmin {
        require(_vestingList[user][vestingType].isActive, "Invalid beneficiary");

        uint256 claimableAmount = _getVestingClaimableAmount(user, vestingType);
        _vestingList[user][vestingType].isActive = false;

        if (claimableAmount > 0) {
            require(totalSupply() + claimableAmount <= _vestingTypes[vestingType].allocation, "Max supply exceeded");
            _mint(user, claimableAmount);
            _vestingList[user][vestingType].claimedAmount = _vestingList[user][vestingType].claimedAmount.add(claimableAmount);
            _projectSupplys[vestingType] = _projectSupplys[vestingType].sub(_vestingList[user][vestingType].amount.sub(_vestingList[user][vestingType].claimedAmount));
        }
    }

    function getVestingInfoByUser(address user, uint256 vestingType) external view returns (VestingInfo memory) {
        return _vestingList[user][vestingType];
    }

    /**
     * @dev
     *
     * Requirements:
     *
     * - `user` cannot be the zero address.
     */
    function _getVestingClaimableAmount(
        address user, 
        uint256 vestingType
    ) internal view returns (uint256 claimableAmount) {
        VestingType memory vestingTypeInfo = _vestingTypes[vestingType];
        VestingInfo memory info = _vestingList[user][vestingType];

        if (!_vestingList[user][vestingType].isActive) return 0;
        if (block.timestamp < vestingTypeInfo.startTimeVesting) return 0;

        claimableAmount = 0;
        
        uint256 roundReleasedAmount = 0;
        uint256 tgeReleasedAmount = 0;
        uint256 releaseTime = vestingTypeInfo.startTimeCliff.add(vestingTypeInfo.cliff.mul(vestingTypeInfo.daysPerCliff).mul(1 days));

        if(vestingTypeInfo.tgePercent > 0) {
            tgeReleasedAmount = info.amount.mul(vestingTypeInfo.tgePercent).div(10000);
        }

        if (block.timestamp >= releaseTime) {
            if(vestingTypeInfo.arbitrary) {
                roundReleasedAmount = info.amount.sub(tgeReleasedAmount);
            }
            else {
                roundReleasedAmount = _calculateLinearReleaseAmount(releaseTime, tgeReleasedAmount, vestingTypeInfo, info);
            }
        }

        if (roundReleasedAmount > info.claimedAmount.sub(tgeReleasedAmount)) {
            claimableAmount = roundReleasedAmount.sub(info.claimedAmount.sub(tgeReleasedAmount));
        }
    }

    function _calculateLinearReleaseAmount(
        uint256 releaseTime, 
        uint256 tgeReleasedAmount,
        VestingType memory vestingTypeInfo,
        VestingInfo memory info
    ) internal view returns (uint256 roundReleasedAmount) {
        roundReleasedAmount = 0;
        uint256 roundsPassed = ((block.timestamp.sub(releaseTime)).div(vestingTypeInfo.daysPerRound.mul(1 days))).add(1);

        if (roundsPassed >= vestingTypeInfo.releaseRounds) {
            roundReleasedAmount = info.amount.sub(tgeReleasedAmount);
        } else {
            roundReleasedAmount = (info.amount.sub(tgeReleasedAmount)).mul(roundsPassed).div(vestingTypeInfo.releaseRounds);
        }
    }

    function getVestingClaimableAmount(address user, uint256 vestingType) external view returns (uint256) {
        return _getVestingClaimableAmount(user, vestingType);
    }

    /**
     * User using this function to claim token as rewards
     * claimPercent describe percentage of claimable token that user want to claim
     * default is 100%
     */
    function claimVestingToken(uint256 vestingType, uint256 claimPercent) external nonReentrant returns (uint256) {
        require(_vestingList[_msgSender()][vestingType].isActive, "Not in vesting list");
        uint256 claimableAmount = _getVestingClaimableAmount(_msgSender(), vestingType).mul(claimPercent).div(10000);
        require(claimableAmount > 0, "Nothing to claim");
        require(totalSupply() + claimableAmount <= _vestingTypes[vestingType].allocation, "Max supply exceeded");

        _vestingList[_msgSender()][vestingType].claimedAmount = _vestingList[_msgSender()][vestingType].claimedAmount.add(claimableAmount);
        _mint(_msgSender(), claimableAmount);

        return claimableAmount;
    }

    receive() external payable {
        revert();
    }
}