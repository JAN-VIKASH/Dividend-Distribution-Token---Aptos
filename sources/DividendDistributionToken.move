module janvikash_addr::DividendToken {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::table::{Self, Table};

    /// Struct representing allowances for delegated transfers
    struct Allowances has store, key {
        allowances: Table<address, u64>,  // spender -> allowed amount
    }

    /// Struct representing the dividend distribution system
    struct DividendPool has store, key {
        total_dividends: u64,     // Total dividends available for distribution
        token_holders: Table<address, u64>,  // holder -> token balance
        total_supply: u64,        // Total tokens in circulation
    }

    /// Function to approve a spender to transfer tokens on behalf of the owner
    public fun approve(
        owner: &signer, 
        spender: address, 
        amount: u64
    ) acquires Allowances {
        let owner_addr = signer::address_of(owner);
        
        // Initialize allowances if they don't exist
        if (!exists<Allowances>(owner_addr)) {
            let allowances = Allowances {
                allowances: table::new(),
            };
            move_to(owner, allowances);
        };
        
        let allowances = borrow_global_mut<Allowances>(owner_addr);
        
        // Set or update the allowance for the spender
        if (table::contains(&allowances.allowances, spender)) {
            *table::borrow_mut(&mut allowances.allowances, spender) = amount;
        } else {
            table::add(&mut allowances.allowances, spender, amount);
        };
    }

    /// Function to transfer tokens from owner to recipient using allowance
    public fun transfer_from(
        spender: &signer,
        owner: address,
        recipient: address,
        amount: u64
    ) acquires Allowances, DividendPool {
        // Check and update allowance
        let allowances = borrow_global_mut<Allowances>(owner);
        let current_allowance = *table::borrow(&allowances.allowances, signer::address_of(spender));
        assert!(current_allowance >= amount, 1); // Insufficient allowance
        
        *table::borrow_mut(&mut allowances.allowances, signer::address_of(spender)) = current_allowance - amount;
        
        // Transfer tokens in the dividend pool
        let pool = borrow_global_mut<DividendPool>(owner);
        let owner_balance = *table::borrow(&pool.token_holders, owner);
        assert!(owner_balance >= amount, 2); // Insufficient balance
        
        // Update balances
        *table::borrow_mut(&mut pool.token_holders, owner) = owner_balance - amount;
        
        if (table::contains(&pool.token_holders, recipient)) {
            let recipient_balance = *table::borrow(&pool.token_holders, recipient);
            *table::borrow_mut(&mut pool.token_holders, recipient) = recipient_balance + amount;
        } else {
            table::add(&mut pool.token_holders, recipient, amount);
        };
    }
}