pub contract TF{

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

    pub fun isNumberInteger(_ number: Number): Bool?{
        if (UFix64(number) % 1.0 == 0.0){
            return true
        }else{
            return nil
        }
    }
}