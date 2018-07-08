pragma solidity ^0.4.11;
contract CrowdFunding {
	// 投資家
	struct Investor {
		address addr;	// 投資家のアドレス
		uint amount;	// 投資額
	}
	
	address public owner;		// コントラクトのオーナー
	uint public numInvestors;	// 投資家の数
	uint public deadline;		// 締め切り(UnixTime)
	string public status;		// キャンペーンのステータス
	bool public ended;			// キャンペーンが終了しているかどうか
	uint public goalAmount;		// 目標額
	uint public totalAmount;	// 投資の総額
	uint public minimum;        // 最低投資額 20180502
	
	mapping (uint => Investor) public investors;	// 投資家管理用のマップ 
	
	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}
	
	/// コンストラクタ
	function CrowdFunding(uint _duration, uint _goalAmount, uint _minimum) {
		owner = msg.sender;

		// 締め切りをUnixTimeで設定
		deadline = now + _duration;

		goalAmount = _goalAmount;
		status = "Funding";
		ended = false;
		minimum = _minimum;    // 最低投資額を任意設定

		numInvestors = 0;
		totalAmount = 0;
	}
	
	/// 投資する際に呼び出される関数
	function fund() payable {
		// キャンペーンが終わっていれば処理を中断する
		require(!ended);
		require((msg.value >= minimum) && ((msg.value + totalAmount) <= goalAmount));
		
		Investor inv = investors[numInvestors++];
		inv.addr = msg.sender;
		inv.amount = msg.value;
		totalAmount += inv.amount;
	}
	
	/// 目標額に達したかを確認する
	/// また、キャンペーンの成功/失敗に応じたetherの送金を行う
	function checkGoalReached () public onlyOwner {		
		// キャンペーンが終わっていれば処理を中断する
		require(!ended);
		
		// 締め切り前の場合は処理を中断する
		require(now >= deadline);
		
		if(totalAmount >= goalAmount) {	// キャンペーンに成功した場合
			status = "Campaign Succeeded";
			ended = true;
			// オーナーにコントラクト内のすべてのetherを送金する
			if(!owner.send(this.balance)) {
				throw;
			}
		} else {	// キャンペーンに失敗した場合
			uint i = 0;
			status = "Campaign Failed";
			ended = true;
			
			// 投資家毎にetherを返金する
			while(i <= numInvestors) {
				if(!investors[i].addr.send(investors[i].amount)) {
					throw;
				}
				i++;
			}
		}
	}
	
	/// コントラクトを破棄するための関数
	function kill() public onlyOwner {
		selfdestruct(owner);
	}
}