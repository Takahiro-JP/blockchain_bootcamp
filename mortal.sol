pragma solidity ^0.4.11; // コントラクトが不要になった場合に破棄するためのコントラクト
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

contract MortalSample is Mortal{
	string public someState;
	
	/// Fallback関数
	function() payable {
	}
	
	/// コンストラクタ
	function MortalSample() {
		// Ownedで定義されているowned関数を呼び出す
		owned();
		
		// someStateの初期値を設定
		someState = "initial";
	}
}