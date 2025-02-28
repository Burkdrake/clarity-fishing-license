import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';

Clarinet.test({
    name: "Test pause functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Pause the contract
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'set-contract-pause', [
                types.bool(true)
            ], deployer.address)
        ]);
        block.receipts[0].result.expectOk(types.bool(true));
        
        // Try to issue license while paused
        block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(8760)
            ], deployer.address)
        ]);
        block.receipts[0].result.expectErr(types.uint(108)); // err-contract-paused
    }
});

[Previous test cases remain unchanged]
