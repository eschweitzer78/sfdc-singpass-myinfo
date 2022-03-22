const express = require('express');
const jose = require('node-jose');
const { verify } = require('jsonwebtoken');

const {
    DecryptDataError,
    InvalidTokenSignatureError,
    MissingAccessTokenError,
    MissingParamsError,
    MyInfoResponseError,
    WrongDataShapeError,
    WrongAccessTokenShapeError,
    InvalidDataSignatureError,
} = require('./errors');

let app = express();

app.use(express.json());

/** 
  * ---------------------------------------
  * DECRYPTING PERSON BODY FOR MYINFO 3.2.0
  * Used for Token Validation as described
  * in MyInfo 3.2.0 documentation:
  * Payload Signing and Encryption (Person)
  * ---------------------------------------
  */


// TODO: Service Provider's (Your) Private MyInfo RSA256 key
const pkcs8_sfdcsg = 
`-----BEGIN PRIVATE KEY-----
BYOK
-----END PRIVATE KEY-----`

// MyInfo public key
const x509_pubmyinfo = 
`-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsGBNIs4nsiHNfLqoR40h
06We1IvWVaGISvETHKlJATWIURd9wx1bqHZ6tesVmLYqKT776kgxXwVD8NP0Vu+T
h8C+IF+9fMNOa8/TeowvcqDiIRjL7RId8kmpcmjtIS2G+MolfSbH7CRWVRko4q88
LMbJUAlglSnFppfQhsEVYlwLtZlHAYy9cl8PcsxPmFUzCUH4Fefyq77BBUPMpzbZ
LLjlAj97rF1oSQJKHM6RBLcvI+AauRpKe34O3GR9bCCTbkhETVerWsemtFUznr9m
oOSaDkEMIGA5wDyt12kjKKvbbm+k2Y5TMq1IIQXfhihGAbTttVpmZLYwJda0nemL
4QIDAQAB
-----END PUBLIC KEY-----`;


app.post('/decodepersonbody', async (req, res, next) => {
    let body = req.body['body'] ? req.body['body'] : null;

    try {
        let r = await decryptJWE(body, pkcs8_sfdcsg, x509_pubmyinfo);

        res.status(200);
        res.send({ status: 'OK', body: r });
    } catch (err) {
        res.status(200);
        res.send({ status: 'KO', error: err.message });
        next(err);
    }
});



/**
  * ----------------------
  * Utility
  * JWE Decryption 
  * ----------------------
  */


/**
  * Decrypts a JWE response string.
  * @param jwe Fullstop-delimited JWE
  * @returns The decrypted data, with signature already verified
  * @throws {DecryptDataError} Throws if an error occurs while decrypting data
  * @throws {InvalidDataSignatureError} Throws if signature on data is invalid
  * @throws {WrongDataShapeError} Throws if decrypted data from MyInfo is
  * of the wrong type
  */
 async function decryptJWE(jwe, privateKeyPemString, signaturePublicKeyPemString) {
    let jwt;
    let decoded;

    try {
        const privateKey = await jose.JWK.asKey(privateKeyPemString, 'pem');
        const { payload } = await jose.JWE.createDecrypt(privateKey).decrypt(jwe);
        jwt = JSON.parse(payload.toString());
    } catch (err) {
        throw new DecryptDataError(err);
    }

    try {
        decoded = verify(jwt, signaturePublicKeyPemString, { algorithms: ['RS256'] });
    } catch (err) {
        throw new InvalidDataSignatureError(err);
    }

    if (typeof decoded !== 'object') {
        throw new WrongDataShapeError();
    }

    return decoded;
}

let port = process.env.PORT || 3000;
app.listen(port);
console.log('Express started on port ' + port);
