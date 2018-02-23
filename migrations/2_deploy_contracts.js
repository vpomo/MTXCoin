const MTXCrowdsale = artifacts.require('./MTXCrowdsale.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner = "0xb79151e54dE4fc0a5940A52A70f5607055AdB73E";
    var wallet = "0xa0AD5e0E8fc86a8440992Ad57B201FaDefBaF595";
    var ownerTwo = "0xb79151e54dE4fc0a5940A52A70f5607055AdB73E";
    //var startTime = 1516406400; // Jan, 20, 2018
    //var startTime = 1513900800; // Dec, 22, 2017
    var startTime = 1445472000; // Oct, 22, 2015

    deployer.deploy(MTXCrowdsale, owner, wallet, ownerTwo, startTime);

};
