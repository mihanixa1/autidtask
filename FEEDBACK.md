1/ typo `Ownabel` (in the docs)
2/ some testsuits fail
  138 passing (21s)
  1 pending
  1 failing
3/ consider using linters (like solhint or so)
4/ consider using code coverage add-ons 
5/ (feature-idea) consider developing a TheGraph api
6/ consider updating solidity version 
7/ some contracts are upgradeable; consider using storage layout checkers for upgrades
8/ (feature-idea) callbacks (inspired by https://github.com/1inch/limit-order-protocol) 
9/ (?) plugin id design hardcode issues
10/ consider using _msgSender() in plugins (maybe use EIP712 in the future?)
11/ consider developing a built-in RBAC lib
12/ consider using hardhat fixtures (reduces amount of duplicates within `before` scopes) 
13/ consider using typescript
14/ consider configuring ci (github actions or so) 
