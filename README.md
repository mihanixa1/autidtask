# changes
`contracts/modules/voting/*`
`contracts/plugins/voting/DemoVoting.sol`


# how to test
`yarn hardhat node &`
`yarn compile && yarn test`


# implementation 

it's a naive solution, which never deletes any proposal and never orders them 

therefore it has some issues: total proposal amount is limited due to block-gas-limit issues as it iterates through all proposals ever created 

ideally, the solution should have some ordered data structure
