const MTXCrowdsale = artifacts.require('./MTXCrowdsale.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner = "0xb79151e54dE4fc0a5940A52A70f5607055AdB73E";
    var wallet = "0xa0AD5e0E8fc86a8440992Ad57B201FaDefBaF595";
    var ownerTwo = "0xb79151e54dE4fc0a5940A52A70f5607055AdB73E";
    var startTime = 1515542400; // Jan, 10, 2018

    deployer.deploy(MTXCrowdsale, owner, wallet, ownerTwo, startTime);

};
