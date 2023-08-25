1/ `Ownabel` in the docs
2/ not all test suites are passing
  138 passing (21s)
  1 pending
  1 failing
3/ linters (like solhint or so) are missing 
4/ coverage plugins are missing 
5/ (feature-idea) it's good to have a subgraph api 
6/ bump solidity version 
7/ some contracts are upgradeable -- there are some migration helper tools for it
   (just for consideration)
8/ (?) use callbacks (inspired by https://github.com/1inch/limit-order-protocol) 
9/ plugin id design hardcode issues
10/ use _msgSender() in plugins (maybe use EIP712 in the future?)
11/ use of a built-in RBAC lib may be considered
12/ 