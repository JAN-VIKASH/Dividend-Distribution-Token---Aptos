module janvikash_addr::DividendToken {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::table::{Self, Table};

    struct Allowances has store, key {
        allowances: Table<address, u64>,  
    }

    struct DividendPool has store, key {
        total_dividends: u64,     
        token_holders: Table<address, u64>,  
        total_supply: u64,        
    }

    public fun approve(
        owner: &signer, 
        spender: address, 
        amount: u64
    ) acquires Allowances {
        let owner_addr = signer::address_of(owner);
        
        if (!exists<Allowances>(owner_addr)) {
            let allowances = Allowances {
                allowances: table::new(),
            };
            move_to(owner, allowances);
        };
        
        let allowances = borrow_global_mut<Allowances>(owner_addr);
        
        if (table::contains(&allowances.allowances, spender)) {
            *table::borrow_mut(&mut allowances.allowances, spender) = amount;
        } else {
            table::add(&mut allowances.allowances, spender, amount);
        };
    }

    public fun transfer_from(
        spender: &signer,
        owner: address,
        recipient: address,
        amount: u64
    ) acquires Allowances, DividendPool {
        let allowances = borrow_global_mut<Allowances>(owner);
        let current_allowance = *table::borrow(&allowances.allowances, signer::address_of(spender));
        assert!(current_allowance >= amount, 1);
        
        *table::borrow_mut(&mut allowances.allowances, signer::address_of(spender)) = current_allowance - amount;
        
        let pool = borrow_global_mut<DividendPool>(owner);
        let owner_balance = *table::borrow(&pool.token_holders, owner);
        assert!(owner_balance >= amount, 2);
        
        *table::borrow_mut(&mut pool.token_holders, owner) = owner_balance - amount;
        
        if (table::contains(&pool.token_holders, recipient)) {
            let recipient_balance = *table::borrow(&pool.token_holders, recipient);
            *table::borrow_mut(&mut pool.token_holders, recipient) = recipient_balance + amount;
        } else {
            table::add(&mut pool.token_holders, recipient, amount);
        };
    }
}
