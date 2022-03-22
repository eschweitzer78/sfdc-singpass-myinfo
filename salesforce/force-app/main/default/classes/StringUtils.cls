public class StringUtils {

    /**
     * Copyright (c) 2021 Emmanuel Schweitzer and Salesforce.com, Inc. All rights reserved.
     * Refer to LICENSE terms attached at the root of this repo.
     */
    
    final static String HEX = '0123456789abcdef';

    // useful
    // public static String fromCharArray(List<Integer> charArray)
    // public List<Integer> getChars()
    // public Integer charAt(Integer index)

    public static String bytesToHex(String s) {
        String result = '';

        for (Integer i = 0; i < s.length(); i++) {
            result += hexFromCharCode(s.charAt(i));
        }

        return result;
    }
    

    public static String hexToBytes(String hex) {
        String rval = '';
        Integer i = 0;

        Integer length = hex.length();
        if ((length & 1) == 1) {
            // odd number of characters, convert first character alone
            i = 1;
            rval += String.fromCharArray(new Integer[] { parseInt16(hex.substring(0, 1)) });
        }

        // convert 2 characters (1 byte) at a time
        for (; i < hex.length(); i += 2) {
            rval += String.fromCharArray(new Integer[] { parseInt16(hex.substring(i, i + 2)) });
        }

        return rval;
    }


    public static Integer parseInt16(String hexString) {
        String[] hexValue = hexString.toLowercase().split('');
        Integer result = 0;
  
        for (Integer index = 0; index < hexValue.size(); index++) {
            result = (result * 16) + HEX.indexOf(hexValue[index]);
        }
  
        return result;
    }


    public static String fromCharCode(Integer charCode) {
        return String.fromCharArray(new Integer[] { charCode });
    }


    public static String UTF8BytesFromCodePoint(Integer codePoint) {
        if (codePoint < 128) {
            return String.fromCharArray(new Integer[] { codePoint });
        } else if (codePoint < 2048) {
            return String.fromCharArray(new Integer[] { (codePoint >> 6) | 192, 
                                                        (codePoint & 63) | 128 });
        } else if (codePoint < 65535) {
            return String.fromCharArray(new Integer[] { (codePoint >> 12) | 224,
                                                        ((codePoint >> 6) & 63) | 128, 
                                                        (codePoint & 63) | 128 });           
        } else {
            return String.fromCharArray(new Integer[] { (codePoint >> 18) | 240,
                                                        ((codePoint >> 12) & 63) | 128,
                                                        ((codePoint >> 6) & 63) | 128,
                                                        (codePoint & 63) | 128 });
        }
    }

    public static String hexFromCharCode(Integer charCode) {
        Integer p1 = (charCode >> 4) & 15;
        Integer p2 = charCode & 15;

        return HEX.substring(p1, p1 + 1) +
               HEX.substring(p2, p2 + 1);
    }  

    public static String hexFromInt(Integer v) {
        Integer p1 = (v >> 28) & 15;
        Integer p2 = (v >> 24) & 15;
        Integer p3 = (v >> 20) & 15;
        Integer p4 = (v >> 16) & 15;
        Integer p5 = (v >> 12) & 15;
        Integer p6 = (v >> 8) & 15;
        Integer p7 = (v >> 4) & 15;
        Integer p8 = v & 15;

        return HEX.substring(p1, p1 + 1) +
               HEX.substring(p2, p2 + 1) +
               HEX.substring(p3, p3 + 1) +
               HEX.substring(p4, p4 + 1) +
               HEX.substring(p5, p5 + 1) +
               HEX.substring(p6, p6 + 1) +
               HEX.substring(p7, p7 + 1) +
               HEX.substring(p8, p8 + 1);
    }


    // Base64url encoding table
    static final List<String> BASE64URLENCTABLE = new List<String> {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
        'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
        'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_'
    };
  
    // Base64url decoding table
    static final List<Integer> BASE64URLDECTABLE = new List<Integer> {
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255,  62, 255, 255,
         52,  53,  54,  55,  56,  57,  58,  59,  60,  61, 255, 255,
        255, 255, 255, 255, 255,   0,   1,   2,   3,   4,   5,   6,
          7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,
         19,  20,  21,  22,  23,  24,  25, 255, 255, 255, 255,  63,
        255,  26,  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,
         37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,  48,
         49,  50,  51, 255, 255, 255, 255, 255
    };


    public class InvalidLengthException extends Exception {}
    public class InvalidCharacterException extends Exception {}


    public static String base64UrlEncode(String input) {
        return base64UrlEncode(StringUtils.toByteArray(input));
    }

    public static String base64UrlEncode(final List<Integer> input) {
        Integer inputLen = input.size();
        Integer n;
        Integer a;
        Integer b;
        Integer c;
        Integer d;
        String output = '';

        // Point to the first byte of the input data
        Integer p = 0;

        // Divide the input stream into blocks of 3 bytes
        n = inputLen / 3;

        // A full encoding quantum is always completed at the end of a quantity
        if (inputLen == (n * 3 + 1)) {
            // The final quantum of encoding input is exactly 8 bits
            if (input != null) {

                //Read input data
                a = (input[n * 3] & 252) >> 2;
                b = (input[n * 3] & 3) << 4;
  
                // The final unit of encoded output will be two characters
                output = BASE64URLENCTABLE[a] + BASE64URLENCTABLE[b];
            }
        } else if (inputLen == (n * 3 + 2)) {
           // The final quantum of encoding input is exactly 16 bits
            if (input != null) {
                // Read input data
                a = (input[n * 3] & 252) >> 2;
                b = ((input[n * 3] & 3) << 4) | ((input[n * 3 + 1] & 240) >> 4);
                c = (input[n * 3 + 1] & 15) << 2;
        
                // The final unit of encoded output will be three characters followed
                output = BASE64URLENCTABLE[a] + BASE64URLENCTABLE[b] + BASE64URLENCTABLE[c];
            }
        } 

        // If the output parameter is NULL, then the function calculates the
        // length of the resulting Base64url string without copying any data
        if (input != null) {
            // The input data is processed block by block
            while (n-- > 0) {
                // Read input data
                a = (input[n * 3] & 252) >> 2;
                b = ((input[n * 3] & 3) << 4) | ((input[n * 3 + 1] & 240) >> 4);
                c = ((input[n * 3 + 1] & 15) << 2) | ((input[n * 3 + 2] & 192) >> 6);
                d = input[n * 3 + 2] & 63;
  
                // Map each 3-byte block to 4 printable characters using the Base64url
                // character set
                output = BASE64URLENCTABLE[a] + BASE64URLENCTABLE[b] + BASE64URLENCTABLE[c] + BASE64URLENCTABLE[d] + output;
            }
        }

        return output;
    }


    public static Blob base64UrlDecodeBlob(final String input) {
        if (String.isBlank(input)) {
            return null;
        }

        return EncodingUtil.base64Decode(input.replace('-', '+')
                .replace('_', '/')
                .rightPad(math.mod(input.length() + (math.mod(4 - input.length(), 4)), 4))
                .replace(' ','='));
    }


    public static String base64DecodeString(final String input) {
        return String.fromCharArray(base64UrlDecode(input));
    }


    public static List<Integer> base64UrlDecode(final String input) {
        Integer inputLen = input.length();
        List<Integer> output = new List<Integer>();

        Long value = 0;
        Integer c;
        Integer i;
        Integer n = 0;
      
        //Check parameters
        if (input == null && inputLen != 0) {
           return output;
        }

        //Check the length of the input string
        if(Math.mod(inputLen, 4) == 1) {
           throw new InvalidLengthException();
        }

        // Process the Base64url-encoded string
        for (i = 0; i < inputLen; i++) {
            //Get current character
            c = input.charAt(i);
      
            //Check the value of the current character
            if (c < 128 && BASE64URLDECTABLE[c] < 64) {
                //Decode the current character
                value = (value << 6) | BASE64URLDECTABLE[c];
        
                //Divide the input stream into blocks of 4 characters
                if ((Math.mod(i, 4)) == 3) {
                    //Map each 4-character block to 3 bytes

                    output.add((Integer) ((value >> 16) & 255));
                    output.add((Integer) ((value >> 8) & 255));
                    output.add((Integer) (value & 255));
      
                    //Decode next block
                    value = 0;
                }
            } else {
                System.debug(input.mid(i, 1));
                // Implementations must reject the encoded data if it contains
                // characters outside the base alphabet
              throw new InvalidCharacterException();
            }
        }
      
        // All trailing pad characters are omitted in Base64url
        Integer m = Math.mod(inputLen, 4);
        if (m == 2) {
            // The last block contains only 1 byte
            output.add((Integer) ((value >> 4) & 255));

            // Adjust the length of the decoded data
            n++;
        } else if (m == 3) {
            // The last block contains only 2 bytes
            // Decode the last two bytes
            output.add((Integer) ((value >> 10) & 255));
            output.add((Integer) ((value >> 2) & 255));
        }

        return output;
    }



    // Base64 encoding table
    static final List<String> BASE64ENCTABLE = new List<String> {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
        'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
        'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
    };

    // Base64 decoding table
    static final List<Integer> BASE64DECTABLE = new List<Integer> {
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, // 0-15
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, // 16-31
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  62, 255, 255, 255,  63, // 32-47
         52,  53,  54,  55,  56,  57,  58,  59,  60,  61, 255, 255, 255, 255, 255, 255, // 48-63
        255,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14, // 64-79
         15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 255, 255, 255, 255, 255, // 80-95
        255,  26,  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40, // 96-111
         41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51, 255, 255, 255, 255, 255  // 112-127
    };


    public static String base64Encode(final List<Integer> input) {
        Integer inputLen = input.size();
        Integer n;
        Integer a;
        Integer b;
        Integer c;
        Integer d;
        String output = '';

        // Point to the first byte of the input data
        Integer p = 0;

        // Divide the input stream into blocks of 3 bytes
        n = inputLen / 3;

        // A full encoding quantum is always completed at the end of a quantity
        if (inputLen == (n * 3 + 1)) {
            // The final quantum of encoding input is exactly 8 bits
            if (input != null) {
                // Read input data
                a = (input[n * 3] & 252) >> 2;
                b = (input[n * 3] & 3) << 4;
  
                // The final unit of encoded output will be two characters
                output = BASE64ENCTABLE[a] + BASE64ENCTABLE[b] + '==';
            }
        } else if (inputLen == (n * 3 + 2)) {
           // The final quantum of encoding input is exactly 16 bits
            if (input != null) {
                // Read input data
                a = (input[n * 3] & 252) >> 2;
                b = ((input[n * 3] & 3) << 4) | ((input[n * 3 + 1] & 240) >> 4);
                c = (input[n * 3 + 1] & 15) << 2;
        
                // The final unit of encoded output will be three characters followed
                // by one "=" padding character
                output = BASE64ENCTABLE[a] + BASE64ENCTABLE[b] + BASE64ENCTABLE[c] + '=';
            }
        }

        // If the output parameter is NULL, then the function calculates the
        // length of the resulting Base64url string without copying any data
        if (input != null) {
            //The input data is processed block by block
            while (n-- > 0) {
                // Read input data
                a = (input[n * 3] & 240) >> 2;
                b = ((input[n * 3] & 3) << 4) | ((input[n * 3 + 1] & 240) >> 4);
                c = ((input[n * 3 + 1] & 15) << 2) | ((input[n * 3 + 2] & 192) >> 6);
                d = input[n * 3 + 2] & 63;
  
                // Map each 3-byte block to 4 printable characters using the Base64url
                // character set
                output = BASE64ENCTABLE[a] + BASE64ENCTABLE[b] + BASE64ENCTABLE[c] + BASE64ENCTABLE[d] + output;
            }
        }

        return output;
    }


    public static List<Integer> base64Decode(final String input) {
        Integer inputLen = input.length();
        List<Integer> output = new List<Integer>();

        Long value = 0;
        Integer c;
        Integer i;
        Integer j = 0;
        Integer padlen = 0;
      
        // Check parameters
        if (input == null && inputLen != 0) {
           return output;
        }

        // Process the Base64-encoded string
        for (i = 0; i < inputLen; i++) {
            // Get current character
            c = input.charAt(i);
      
            // Check the value of the current character
            if (c == 10 || c == 13) {
                // CR and LF should be ignored
            } else if (c == 61) { // =
                padLen++;
            } else if (c < 128 && (BASE64DECTABLE[c] < 64) && (padlen == 0)) {
                // Decode the current character
                value = (value << 6) | BASE64DECTABLE[c];
        
                //Divide the input stream into blocks of 4 characters
                if (++j == 4) {
                    //Map each 4-character block to 3 bytes

                    output.add((Integer) ((value >> 16) & 255));
                    output.add((Integer) ((value >> 8) & 255));
                    output.add((Integer) (value & 255));
      
                    // Decode next block
                    j = 0;
                    value = 0;
                }
            } else {
                // Implementations must reject the encoded data if it contains
                // characters outside the base alphabet
              throw new InvalidCharacterException();
            }
        }
      
        // Check the number of pad characters
        if (padLen == 0 && j == 0) {
            // No pad
        } else if (padLen == 1 && j == 3) {
            // Decode the last two bytes
            output.add((Integer) ((value >> 10) & 255));
            output.add((Integer) ((value >> 2) & 255));
        } else if (padLen == 2 && j == 2) {
            //The "==" sequence indicates that the last block contains only 1 byte
            output.add((Integer) ((value >> 4) & 255));

            // Skip trailing pad characters
            i++;
        }

        return output;
    }


    public static List<Integer> toByteArray(String s) {
        List<Integer> result = new Integer[s.length()];

        for (Integer i = 0; i < s.length(); i++) {
            result[i] = s.charAt(i);
        }

        return result;
    }


    public static String fromByteArray(List<Integer> a) {
        return String.fromCharArray(a);
    }
}