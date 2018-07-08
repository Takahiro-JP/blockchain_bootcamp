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
	function changeOwner(address _newOwner) internal onlyOwner {
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

contract BulletinBoard is Mortal, CircuitBreaker {
    //  投稿者用の構造体
    struct Contributer {
		string username;          //  名前
		string mailaddress;   //  メールアドレス
		string message;       //  投稿内容
		address addr;        //  アドレス
	}
	//  投稿を管理するマップ
	mapping(uint => Contributer) private Contributers;
	string private boardname; //  掲示板タイトル
	uint private maxcontribute;    //  最大投稿数
	uint private postnumber;
	
	/// コンストラクタ
	function bulletinboard (string _boardname) external {
		boardname = _boardname;    //  掲示板タイトル
		maxcontribute = 1000;
		postnumber = 0;
	}
	
	/// 投稿用関数　
	function Post (string _username, string _mailaddress, string _message) external {
	    Contributer storage con = Contributers[postnumber++];
	    con.addr = msg.sender;
	    if (bytes(_username).length == 0){
	        con.username = "user";
	    } else {
	    con.username = _username;
	    }
	    con.mailaddress = _mailaddress;
	    con.message = _message;
	    require((bytes(con.message).length) != 0);
	}
	
	/// 投げ銭用関数　
	function Tip (uint _postnumber) external payable {
	    Contributers[_postnumber].addr.send(msg.value);
	}
}