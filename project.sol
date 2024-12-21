// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract RewardsForAnsweringQuestions {
    address public owner;
    IERC20 public rewardToken; // ERC20 Token used for rewards
    uint256 public rewardAmount; // Reward amount per valid answer
    mapping(uint256 => Question) public questions;
    mapping(address => uint256) public userRewardBalance;

    struct Question {
        uint256 id;
        string content;
        address asker;
        uint256 answerCount;
        mapping(address => bool) answered;
        bool answeredCorrectly;
    }

    event QuestionAsked(uint256 questionId, address asker, string content);
    event AnswerSubmitted(uint256 questionId, address answerer);
    event RewardClaimed(address user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier questionExists(uint256 questionId) {
        require(bytes(questions[questionId].content).length > 0, "Question does not exist");
        _;
    }

    modifier onlyNotAnswered(uint256 questionId) {
        require(!questions[questionId].answered[msg.sender], "You have already answered this question");
        _;
    }

    modifier canClaimReward(uint256 questionId) {
        require(questions[questionId].answeredCorrectly, "Answer is not correct");
        _;
    }

    constructor(IERC20 _rewardToken, uint256 _rewardAmount) {
        owner = msg.sender;
        rewardToken = _rewardToken;
        rewardAmount = _rewardAmount;
    }

    function askQuestion(string memory content) external {
        uint256 questionId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, content)));
        Question storage newQuestion = questions[questionId];
        newQuestion.id = questionId;
        newQuestion.content = content;
        newQuestion.asker = msg.sender;
        newQuestion.answerCount = 0;
        emit QuestionAsked(questionId, msg.sender, content);
    }

    function submitAnswer(uint256 questionId) external questionExists(questionId) onlyNotAnswered(questionId) {
        Question storage q = questions[questionId];
        q.answered[msg.sender] = true;
        q.answerCount++;

        // Mark the answer as correct for demonstration purposes.
        // In a real application, you might have a mechanism for verifying answers.
        if (q.answerCount == 1) {
            q.answeredCorrectly = true;
        }

        emit AnswerSubmitted(questionId, msg.sender);
    }

    function claimReward(uint256 questionId) external questionExists(questionId) canClaimReward(questionId) {
        require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Insufficient contract balance");
        
        // Transfer the reward
        rewardToken.transfer(msg.sender, rewardAmount);
        userRewardBalance[msg.sender] += rewardAmount;
        
        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function updateRewardAmount(uint256 newAmount) external onlyOwner {
        rewardAmount = newAmount;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        rewardToken.transfer(owner, amount);
    }
}
