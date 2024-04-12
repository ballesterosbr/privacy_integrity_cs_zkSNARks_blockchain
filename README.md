# Enhancing Privacy and Integrity in Computing Services Provisioning Using Blockchain and zk-SNARKs

In this repository, the files used within the context of the paper *Enhancing Privacy and Integrity in Computing Services Provisioning Using Blockchain and zk-SNARKs are found*.

## Libraries

- [`nodejs v20.11.0`](https://nodejs.org/en/blog/release/v20.11.0)
- [`snarkjs@0.7.0`](https://github.com/iden3/snarkjs/releases/tag/v0.7.0)
- [`circom compiler 2.1.4`](https://github.com/iden3/circom/releases/tag/v2.1.4)

## Files included in this repository
- Circom Circuits Library
- Circom Circuits for Custom CNN Models
    - Circuit Inputs
    - Circuit Outputs
- For each custom CNN model and zk-SNARK construction (Groth16, Plonk, Fflonk)
    - Verifier Smart Contracts 
    - Escrow & Proprietary Algorithm Verifier Smart Contracts
        - Transaction Inputs 
    - Proofs
    - Public Signals

**Note:** Some files are not included in this repository due to their large size. However, the procedure to replicate the acquisition of these files is provided below. These include:
- R1CS files
- Powers of Tau file
- Witness file
- Zero-knowledge keys

## Powers of Tau file

| Power | Max Constraints | Size | File | SHA-256 hash |
|---|---|---|---|---|
| 24 | 16M | 19,3 GB | [powersOfTau28_hez_final_24.ptau](https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_24.ptau) | 032647abe127f4562f8118dd5f866ab595c1f2bbd03d0a85ff3739a4a967d9be |

Due to the complexity of the arithmetic circuits outlined in this study, a `ptau` file with a number of constraints equal to $2^{24}$ is employed, surpassing the constraints of the proposed circuits. The fact that the `ptau` file generated in a ceremony process has a number of constraints greater than those of an arithmetic circuit contributes to greater cryptographic security of the framework. This is particularly relevant because the ptau file must have a sufficient number of constraints to encompass the complexity of the arithmetic circuit, which is especially crucial in complex applications such as program verification. Additionally, the chosen curve, colloquially referred to as BN128, is the Barreto-Naehrig Curve from [Pairing-Friendly Elliptic Curves of Prime Order
](https://link.springer.com/chapter/10.1007/11693383_22), offering a 128-bit security level.

## Circuits

- Custom CNN1 model: [`CNN1.circom`](CNN1/CNN1.circom)
- Custom CNN2 model: [`CNN2.circom`](CNN2/CNN2.circom)
- Custom CNN3 model: [`CNN3.circom`](CNN3/CNN3.circom)

## Compile the Circuit & Generate R1CS

Use the following command to generate the R1CS constraint system for the circuit:

```
$ circom CNNx.circom --r1cs
```

markdown

Where `x` represents the number of the custom CNN model. This command will generate the following files:
- `CNN1.r1cs`
- `CNN2.r1cs`
- `CNN3.r1cs`

These `r1cs` files represent the Rank-1 Constraint System (R1CS) for the respective CNN models, encapsulating the necessary constraints for zk-SNARK proof generation and verification.


## Circuit Information

Use the following command to print the circuit statistics:

```
$ snarkjs r1cs info CNNx.r1cs
```

Where `x` represents the number of the custom CNN model.

The command provides the following circuit information:
- Elliptic curve
- Number of wires
- Number of constraints
- Number of public inputs
- Number of private inputs
- Number of outputs

## Witness generation

Use the following command to generate the `witness.wtns` file, which includes the witness:

```
$ node generate_witness.js CNNx.wasm CNNx_input.json witness.wtns
```
- The Wasm file for each custom CNN used to generate the witness is created using: 

    `$ circom CNNx.circom --wasm`

- Circuit inputs are provided in JSON format, which varies for each custom CNN model: 
    `CNNx_input.json`

Where `x` represents the number of the custom CNN model.

## Zero-knowledge key generation

For each custom CNN model, run the following commands:

### Plonk
```
$ snarkjs plonk setup CNNx.r1cs powersOfTau28_hez_final_24.ptau.ptau CNNx_final.zkey
```

### Fflonk
```
$ snarkjs fflonk setup CNNx.r1cs powersOfTau28_hez_final_24.ptau.ptau CNNx_final.zkey
```

### Groth16
```
$ snarkjs groth16 setup CNNx.r1cs powersOfTau28_hez_final_24.ptau.ptau CNNx_final.zkey
```

For Groth16 an additional ceremony process for each circuit is required, which is not covered in this document. You can read more in the official documentation of [snarkjs](https://github.com/iden3/snarkjs?tab=readme-ov-file#groth16).

Where `x` represents the number of the custom CNN model.

These commands generate the zero-knowledge keys (`CNNx_final.zkey`) for each custom CNN model using different zk-SNARK proof systems: Plonk, Fflonk, and Groth16, respectively.

## Proof Generation

For each custom CNN model, run the following commands:

### Plonk
```
$ snarkjs plonk prove CNNx_final.zkey witness.wtns proof.json public.json
```

### Fflonk
```
$ snarkjs fflonk prove CNNx_final.zkey witness.wtns proof.json public.json
```

### Groth16
```
$ snarkjs groth16 prove CNNx_final.zkey witness.wtns proof.json public.json
```

Where `x` represents the number of the custom CNN model.


These commands generate the proofs (`proof.json`) for each custom CNN model using different proof systems: Plonk, Fflonk, and Groth16, respectively. The proof and public inputs are stored in `proof.json` and `public.json` files, respectively.


## Verifier smart contract generation

For each custom CNN model, run the following commands:

### Plonk
```
$ snarkjs zkey export solidityverifier CNNx_final.zkey PlonkVerifier.sol
```

### Fflonk
```
$ snarkjs zkey export solidityverifier CNNx_final.zkey FflonkVerifier.sol
```

### Groth16
```
$ snarkjs zkey export solidityverifier CNNx_final.zkey Groth16Verifier.sol
```

## Smart Contract Deployment

To deploy the smart contracts from the previous step, you can use a network like Ethereum. You can also employ online tools that allow testing of smart contracts such as [RemixIDE](https://remix.ethereum.org/).

After deploying the `XXXXXVerifier.sol` contracts for each custom CNN model, you need to deploy the smart contract that imports the verification function and the payment logic. These contracts, named `escrowZKMLVerifier.sol`, are located at the following paths:

Within the folders for each CNN model:
- `fflonk/escrowZKMLVerifier.sol`
- `groth16/escrowZKMLVerifier.sol`
- `plonk/escrowZKMLVerifier.sol`

## Generation times
To compute the generation times of the elements described above, simply do so using commands that allow measuring the execution time of operations.

## Smart Contract Interaction

To evaluate the developed framework, inputs are provided as function parameters for each "Escrow & Proprietary Algorithm Verifier" for each particular case. These inputs are available in the `escrowZKMLVerifier_inputs` file.

In order to obtain the metrics related to the Gas cost, it is necessary to interact with the smart contract and retrieve data regarding the gas used in each transaction.

## Acknowledgements

Some Circom circuits corresponding to common layers found in CNNs have been sourced from the following library:

- [Circom Circuits Library for Machine Learning](https://github.com/socathie/circomlib-ml)
