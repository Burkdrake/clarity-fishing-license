[Previous test content]

Clarinet.test({
    name: "Test minimum duration requirement",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Try to issue license with duration less than minimum
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(4380)  // 1 month in blocks
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(107)); // err-invalid-duration
    }
});
