/**
    Trading Functions is a utility library for keeping apart some weird functions
    needed by the contracts to run the maths over the cards distribution
*/


pub contract TF{
    /*
        getNumbersDictionaryMinimun gets a numeric dictionary and returns the minimun value
        Arguments: _dictionary A dictionary having numbers as keys and values
        Return: min The lower of the dictionary values
     */
    pub fun getNumbersDictionaryMinimun(_ dictionary: {Number: Number}): Number{
        pre{
            dictionary.keys.length > 0 : "Dictionary is empty"
        }
        var min = dictionary[dictionary.keys[0]]!
        for key in dictionary.keys{
            if (dictionary[key]! < min){
                min = dictionary[key]!
            }
        }
        return min
    }

    /*
        getNumbersDictionaryMaximun gets a numeric dictionary and returns the maximun value
        Arguments: _dictionary A dictionary having numbers as keys and values
        Return: max The higher of the dictionary values
     */
    pub fun getNumbersDictionaryMaximun(_ dictionary: {Number: Number}): Number{
        pre{
            dictionary.keys.length > 0 : "Dictionary is empty"
        }
        var max = dictionary[dictionary.keys[0]]!
        for key in dictionary.keys{
            if (dictionary[key]! > max){
                max = dictionary[key]!
            }
        }
        return max
    }

    /*
        isNumberInteger checks if a number is integer regardless of his type
        Arguments: _number The number to check
        Return: True if the number is integer nil instead (for ?? panic use)
     */
    pub fun isNumberInteger(_ number: Number): Bool?{
        if (UFix64(number) % 1.0 == 0.0){
            return true
        }else{
            return nil
        }
    }

    /*
        generateAcotatedRandom generates a random number within a range
        Arguments: _max The limit of the generated number
        Return: acotatedRandom The acotated value {0,(max-1)}
    */
    pub fun generateAcotatedRandom(_ max: UInt64): UInt64{
        let random = unsafeRandom()
        let acotatedRandom = random % max
        return acotatedRandom
    }
}
 