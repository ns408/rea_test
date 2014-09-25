REA pre-interview questions
====

#### Reason for choosing rbenv:
- Allows version specifications for gems

##### Drawbacks
- Takes ages to deploy

#### Purpose
##### rea_test.sh
- Setup puppet, facter, git
- Grab required modules
#### rea_test.pp  
- Setup apache, passenger, gems
- Grab application code
- Enable iptables

#### How to use
```
cd /tmp
git clone https://github.com/ns408/rea_test && cd rea_test && bash rea_test.sh
```
