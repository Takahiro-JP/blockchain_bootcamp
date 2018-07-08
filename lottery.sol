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
	function CircuitBreaker() public {
		owned();
		stopped = false;
	}
	
	/// stoppedの状態を変更
	function toggleCircuit(bool _stopped) public onlyOwner {
		stopped = _stopped;
	}
}

contract Lottery is Mortal, CircuitBreaker {
    // 購入者
    struct Purchaser {
		address addr;	        // 購入者のアドレス
		uint amount;            // 購入額
	}
	mapping(uint => Purchaser) public purchasers;	// 購入者を管理するマップ
	uint public num_Purchaser;                      // 購入者数
	uint public totalAmount;                        // 総購入額
    
    address public winner;                          // 当選者
    uint public lottery_number;                     //当選番号
    //uint public winnig_amount;                      // 当選額
	uint public minimum_purchasers;                 // くじ実行最低購入者数
	uint public deadline;                           // 購入受付終了時間
	bool public ended = false;                      // 購入受付終了判定
    mapping (address => uint) public userBalances; // 応募者の返金マップ
    uint public getparcent;                         // オーナーの取り分
	
	/// コンストラクタ
	function Lottery(uint _duration) payable public {
		winner = msg.sender;
		deadline = now + _duration;
		minimum_purchasers = 3;
		num_Purchaser = 0;
		getparcent = 1;
	}
	
	/// Purchaser用の関数
	function purchaser() public payable isStopped {
	    require(!ended); // 受付終了でないことの確認
	    require(now <= deadline); // 時間切れでないことの確認

		// くじ購入者の管理
		Purchaser storage pur = purchasers[num_Purchaser++];
		pur.addr = msg.sender;
		pur.amount = msg.value;
		totalAmount += pur.amount;
	}
	
	///オーナーへの送金処理
	function EndLottery() public payable onlyOwner {
	    require(!(num_Purchaser < minimum_purchasers)); //最低購入者数を上回っていることの確認
	    ended = true;
	    uint timestamp = block.timestamp;
	    lottery_number = timestamp % num_Purchaser;
	    winner = purchasers[lottery_number].addr;
	    owner.transfer(totalAmount * (getparcent / 100));
	}
	
	///当選者への送金
	function withdraw() public payable {
	    require(ended == true );
		// 返金額を退避
		uint refundAmount = totalAmount - totalAmount * (getparcent / 100);
		
		// 返金処理
		if(!msg.sender.send(refundAmount)) {
			revert();
		}
	}
}