import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test license issuance",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(52560)  // ~1 year in blocks
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Test license renewal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // First issue a license
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(52560)
            ], deployer.address)
        ]);
        
        // Then renew it
        let renewBlock = chain.mineBlock([
            Tx.contractCall('fishing-license', 'renew-license', [
                types.uint(1),
                types.uint(52560)
            ], user1.address)
        ]);
        
        renewBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Test license transfer with approval",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        const user2 = accounts.get('wallet_2')!;
        
        // Issue license to user1
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user1.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(52560)
            ], deployer.address)
        ]);
        
        // Approve transfer to user2
        let approveBlock = chain.mineBlock([
            Tx.contractCall('fishing-license', 'approve-transfer', [
                types.uint(1),
                types.some(types.principal(user2.address))
            ], user1.address)
        ]);
        
        // Transfer license to user2
        let transferBlock = chain.mineBlock([
            Tx.contractCall('fishing-license', 'transfer-license', [
                types.uint(1),
                types.principal(user2.address)
            ], user1.address)
        ]);
        
        transferBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Test unauthorized license issuance",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user1 = accounts.get('wallet_1')!;
        const user2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('fishing-license', 'issue-license', [
                types.principal(user2.address),
                types.ascii("Annual"),
                types.ascii("Lake Michigan"),
                types.uint(52560)
            ], user1.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(100)); // err-owner-only
    }
});
