pragma solidity ^0.4.11; // 緊急停止装置
contract Owned {
	address public owner;
	
	/// アクセスチェック用のmodifier
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	/// オーナーを設定
	function owned() internal {
		owner = msg.sender;
	}
}

contract CircuitBreaker is Owned {
	bool public stopped;	// trueの場合、Circuit Breakerが発動している
	bytes16 public message;

	/// stopped変数を確認するmodifier	
	modifier isStopped() {
		require(!stopped);
		_;
	}

	/// コンストラクタ
	function CircuitBreaker() {
		owned();
		stopped = false;
	}
	
	/// stoppedの状態を変更
	function toggleCircuit(bool _stopped) public onlyOwner {
		stopped = _stopped;
	}
}
		
	/// messageを更新する関数
	/// stopped変数がtrueの場合は更新出来ない
contract CircuitBreakersample is CircuitBreaker {
	
	function setMessage(bytes16 _message) public isStopped  {
		message = _message;
	}
}
