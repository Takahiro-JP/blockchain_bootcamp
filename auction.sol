pragma solidity ^0.4.11;
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
	
	///　オーナーを変更する
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}
}

contract Mortal is Owned {
	/// コントラクトを破棄して、etherをownerに送る
	function kill() public onlyOwner {
		selfdestruct(owner);
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

contract AuctionWithdraw is Mortal, CircuitBreaker {
	address public highestBidder;	// 最高額提示アドレス
	uint public highestBid;	// 最高提示額
	mapping(address => uint) public userBalances;	// 返金額を管理するマップ
	uint public deadline;   //入札受付終了時間
	bool public ended = false; //オークション終了判定
	
	/// コンストラクタ
	function AuctionWithdraw(uint _duration) payable {
		highestBidder = msg.sender;
		highestBid = 0;
		deadline = now + _duration;
	}
	
	/// Bid用の関数
	function bid() public payable isStopped {
	    require(!ended);
		// bidが現在の最高額よりも大きいことを確認する
		require(msg.value > highestBid);

		// 最高額提示アドレスの返金額を更新する
		userBalances[highestBidder] += highestBid; //新しい投資家のアドレスと金額
				
		// ステート更新
		highestBid = msg.value; //オーナーへの送金用
		highestBidder = msg.sender; //オーナーへの送金用
	}
	
	///オーナーへの送金処理
	function EndAuction()  onlyOwner {
	    ended = true;
	    owner.send(highestBid);
	}
	
	///返金処理
	function withdraw() public{
		// 返金額が0より大きいことを確認する
		require(userBalances[msg.sender] > 0);
		
		// 返金額を退避
		uint refundAmount = userBalances[msg.sender];
		
		// 返金額を更新
		userBalances[msg.sender] = 0;
		
		// 返金処理
		if(!msg.sender.send(refundAmount)) {
			throw;
		}
	}
}