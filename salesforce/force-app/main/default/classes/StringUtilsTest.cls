@isTest
private class StringUtilsTest {

    /**
     * Copyright (c) 2021 Emmanuel Schweitzer and Salesforce.com, Inc. All rights reserved.
     * Refer to LICENSE terms attached at the root of this repo.
     */
    
    static @isTest void testUTF8BytesFromCodePoint() {
        // 1200074 is 0b011101 010100 001010
        // should be broken down as follows:
        // 240 = 0b11110 000
        // 157 = 0b10 011101
        // 148 = 0b10 010100
        // 138 = 0b10 001010
        String r = StringUtils.UTF8BytesFromCodePoint(120074);
        System.assertEquals(4, r.length());
        System.assertEquals(240, r.charAt(0));
        System.assertEquals(157, r.charAt(1));
        System.assertEquals(148, r.charAt(2));
        System.assertEquals(138, r.charAt(3));

        // 3026 is 0b00000 101111 010010
        // should be broken down as follows:
        // 224 = 0b111 00000
        // 175 = 0b10 101111
        // 146 = 0b10 010010
        r = StringUtils.UTF8BytesFromCodePoint(3026);
        System.assertEquals(3, r.length());
        System.assertEquals(224, r.charAt(0));
        System.assertEquals(175, r.charAt(1));
        System.assertEquals(146, r.charAt(2));

        // 1043 is 0b10000 010011
        // should be broken down as follows:
        // 208 = 0b110 10000
        // 147 = 0b10 010011
        r = StringUtils.UTF8BytesFromCodePoint(1043);
        System.assertEquals(2, r.length());
        System.assertEquals(208, r.charAt(0));
        System.assertEquals(147, r.charAt(1));


        r = StringUtils.UTF8BytesFromCodePoint(120);
        System.assertEquals(1, r.length());
        System.assertEquals(120, r.charAt(0));
    }

    static @isTest void testBase64Decode() {
        String initial = '{"typ":"JWT","alg":"ES512","kid":"keyidentifier1"}';
        Blob b = Blob.valueOf(initial);
        String enc = EncodingUtil.base64Encode(b);

        System.assertEquals(initial, String.fromCharArray(StringUtils.base64decode(enc)));
    }

    static @isTest void testBase64UrlDecode() {
        List<Integer> r = StringUtils.base64UrlDecode('SGV5IGhvdyBhcmUgeW91IQ');
        System.assertEquals('Hey how are you!', String.fromCharArray(r));
        
        r = StringUtils.base64UrlDecode('eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiIsImtpZCI6ImtleWlkZW50aWZpZXIxIn0');
        System.assertEquals('{"typ":"JWT","alg":"ES512","kid":"keyidentifier1"}', String.fromCharArray(r));        
    }
    
    static @isTest void testBase64UrlEncode() {
        String r = StringUtils.base64UrlEncode(StringUtils.toByteArray('Hey how are you!'));
        System.assertEquals('SGV5IGhvdyBhcmUgeW91IQ', r);

        r = StringUtils.base64UrlEncode(StringUtils.toByteArray('{"typ":"JWT","alg":"ES512","kid":"keyidentifier1"}'));
        System.assertEquals('eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzUxMiIsImtpZCI6ImtleWlkZW50aWZpZXIxIn0', r);
        
    }
}