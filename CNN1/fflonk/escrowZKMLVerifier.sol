// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './FflonkVerifier.sol';
//import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract escrowZKMLVerifier is Ownable {

    FflonkVerifier public myVerifier;

    struct proof_data {
        bytes32 sealedSeed;
        uint256 storedBlockNumber;
        bytes32[] proofs;                           // array of submitted proofs
        uint256[] evaluableProofs;                  // array of evaluable proof
        uint256 proofsRequired;                     // Proofs required by client
        mapping (bytes32 => bool) proofExistence;   // true = proof submitted
        mapping (bytes32 => bool) proofToEval;      // true = proof seleccted to be evaluated
    }

    uint256 totalProofs = 1;

    mapping(address => proof_data) client_proofs;
    mapping(address => uint256) balanceOf;

    constructor(address verifierAddress) Ownable(msg.sender) {
        myVerifier = FflonkVerifier(verifierAddress);
    }

    function deposit(bytes32 _sealedSeed, uint256 _proofsRequired) external payable {
        require(balanceOf[msg.sender] == 0);
        require(msg.value > 0);

        client_proofs[msg.sender].sealedSeed = _sealedSeed;
        client_proofs[msg.sender].storedBlockNumber = block.number + 1;
        client_proofs[msg.sender].proofsRequired = _proofsRequired;

        balanceOf[msg.sender] = msg.value;
    }

    function addProofs(address _client, bytes32[] calldata _proofHash) external onlyOwner {
        require(balanceOf[_client] > 0);
        for (uint256 i = 0; i < _proofHash.length; i++) {
            if(client_proofs[_client].proofExistence[_proofHash[i]] == false) {
                client_proofs[_client].proofs.push(_proofHash[i]);
                client_proofs[_client].proofExistence[_proofHash[i]] = true;
            }
        }
    }

    function selectProofs(bytes32 _seed) external returns (bool) {
        require(client_proofs[msg.sender].proofs.length == totalProofs);
        require(client_proofs[msg.sender].evaluableProofs.length == 0);
        require(client_proofs[msg.sender].storedBlockNumber < block.number);
        require(sha256(abi.encode(msg.sender, _seed)) == client_proofs[msg.sender].sealedSeed);

        uint8 pseudorandomIndex = uint8(uint256(sha256(abi.encode(_seed, blockhash(client_proofs[msg.sender].storedBlockNumber)))) % client_proofs[msg.sender].proofs.length);
        
        for (uint256 i = 0; i < client_proofs[msg.sender].proofsRequired; i++) {
            uint256 index = (pseudorandomIndex + i) % client_proofs[msg.sender].proofs.length;        
            client_proofs[msg.sender].evaluableProofs.push(index);
            client_proofs[msg.sender].proofToEval[client_proofs[msg.sender].proofs[index]] = true;
        }
        return true;
    }

    function withdraw(address _client, address payable _to) external onlyOwner {
        require(client_proofs[_client].proofs.length == totalProofs);
        require(client_proofs[_client].proofsRequired == 0);

        (bool success, ) = _to.call{value: balanceOf[_client]}("");
        require(success);
    }

    function verifyProof(address _client, bytes32 _proof_hash, bytes32[24] calldata proof, uint256[11] calldata pubSignals) external onlyOwner returns (bool) {
        require(getProofHash(proof, pubSignals) == _proof_hash);
        require(client_proofs[_client].proofExistence[_proof_hash]);
        require(client_proofs[_client].proofToEval[_proof_hash]);
        require(client_proofs[_client].proofsRequired > 0);

        (bool success, bytes memory data) = address(myVerifier).staticcall(abi.encodeWithSelector(myVerifier.verifyProof.selector, proof, pubSignals));
        require(success);
        require(abi.decode(data, (bool)));

        client_proofs[_client].proofToEval[_proof_hash] = false;
        client_proofs[_client].proofsRequired--;

        return true;
    }

    function getProofsToEvaluate(address _client) external view onlyOwner returns (uint256[] memory) {
        return client_proofs[_client].evaluableProofs;
    }

    function getProofHash(bytes32[24] calldata proof, uint256[11] calldata pubSignals) public pure returns (bytes32) {
        return sha256(abi.encode(proof, pubSignals));
    }

    function getProofExistence(address _client, bytes32 _proof_hash) public view returns (bool) {
        return client_proofs[_client].proofExistence[_proof_hash];
    }

    function isEvaluableProof(address _client, bytes32 _proof_hash) public view returns (bool) {
        return client_proofs[_client].proofToEval[_proof_hash];
    }

    function getUserData(address _client) public view returns (uint256, uint256) {
        return( client_proofs[_client].proofs.length,
                client_proofs[_client].proofsRequired
                );
    }
}