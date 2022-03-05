transaction(contract: String) {
    
    prepare(signer: AuthAccount) {    
        signer.contracts.add(name: "FlowToken", 
                            code: contract.decodeHex(), 
                            adminAccount: signer)
    }
}
 