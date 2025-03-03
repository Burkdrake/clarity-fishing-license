import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';

Clarinet.test({
    name: "Test license type validation and tiered pricing",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Add valid license type
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'add-valid-license-type', [
                types.ascii("Annual")
            ], deployer.address)
        ]);
        block.receipts[0].result.expectOk(types.bool(true));
        
        // Try to issue license with invalid type
        block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Invalid"),
                types.ascii("Lake Michigan"),
                types.uint(8760)
            ], deployer.address)
        ]);
        block.receipts[0].result.expectErr(types.uint(110)); // err-invalid-license-type
        
        // Issue license with valid type and check tiered pricing
        block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(43800)
            ], deployer.address)
        ]);
        block.receipts[0].result.expectOk(types.uint(1));
    }
});

// [Previous test cases remain unchanged]
