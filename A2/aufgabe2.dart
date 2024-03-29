import 'dart:io';

class MapManyToManyException implements Exception {}

class Skewer {
  final List<int> bowlNumbers;
  final List<String> fruits;

  Skewer(this.bowlNumbers, this.fruits);

  bool get isEmpty => bowlNumbers.isEmpty;
  bool get isNotEmpty => bowlNumbers.isNotEmpty;

  //removes overlapping sections of skewer and returns overlapping skewer (containing empty lists if nothing is overlapping)
  //2 Skewer can only have n fruits so O=(n^2), n=fruits
  Skewer cutOverlap(Skewer skewer) {
    List<int> overlapBowlNumbers = [];
    List<String> overlapFruits = [];

    //do not cutOverlap the same skewer
    if (this == skewer) {
      print("useless cut");
      return Skewer(overlapBowlNumbers, overlapFruits);
    }
    //add overlap
    for (int i = 0; i < bowlNumbers.length; i++) {
      for (int j = 0; j < skewer.bowlNumbers.length; j++) {
        if (bowlNumbers[i] == skewer.bowlNumbers[j]) {
          overlapBowlNumbers.add(bowlNumbers[i]);
        }
        if (fruits[i] == skewer.fruits[j]) {
          overlapFruits.add(fruits[i]);
        }
      }
    }

    if (overlapBowlNumbers.length != overlapFruits.length) {
      throw "Inconsistent data";
    }

    //remove overlapping elements
    skewer.bowlNumbers.removeWhere((element) {
      return overlapBowlNumbers.contains(element);
    });
    skewer.fruits.removeWhere((element) {
      return overlapFruits.contains(element);
    });

    bowlNumbers.removeWhere((element) {
      return overlapBowlNumbers.contains(element);
    });
    fruits.removeWhere((element) {
      return overlapFruits.contains(element);
    });

    return Skewer(overlapBowlNumbers, overlapFruits);
  }

  MapEntry<String, int> getMapEntry() {
    if (bowlNumbers.length > 1) {
      throw MapManyToManyException();
    }
    return MapEntry(fruits[0], bowlNumbers[0]);
  }

  @override
  String toString() {
    return "$bowlNumbers = $fruits";
  }
}

//run by using cmd: 1. go in the current dict 2. run: dart aufgabe2.dart
void main() async {
  List<String> filenames = [
    "spiesse0.txt", //given example
    "spiesse1.txt",
    "spiesse2.txt",
    "spiesse3.txt",
    "spiesse4.txt",
    "spiesse5.txt",
    "spiesse6.txt",
    "spiesse7.txt",
    "spiesse8.txt", //for >1 unnoted fruits
    "spiesse9.txt", //to many unknown fruits
  ];
  for (String filename in filenames) {
    File file = await File("beispiele\\$filename");
    //readAsLines to also handle CR LF endings
    List<String> lines = await file.readAsLines();
    lines.removeWhere((element) => element.isEmpty); //remove empty lines
    int nFruits = int.parse(lines[0]);
    List<String> targetFruits = extractFruitsFrom(lines[1]);
    int nSkewer = int.parse(lines[2]);
    List<Skewer> skewers = [];
    //create skewers, starting from line 3
    for (int n = 3; n < nSkewer * 2 + 3; n += 2) {
      List<int> bowlNumbers = [];

      List<String> tmp = lines[n].split(" ");
      tmp.removeWhere((element) => element.isEmpty);
      bowlNumbers = tmp.map((e) {
        return int.parse(e);
      }).toList();

      List<String> fruits = extractFruitsFrom(lines[n + 1]);

      skewers.add(Skewer(bowlNumbers, fruits));
    }
    try {
      List<int> solution = solve(skewers, targetFruits, nFruits);
      print("\nSolution for $filename, use bowls: $solution\n");
    } catch (exception) {
      print("\n$filename: $exception\n");
    }
  }
}

//O=(n^3) of assigning combinations, n=fruits dominated by O(reduce())
List<int> solve(List<Skewer> skewers, List<String> targetFruits, int nFruits) {
  List<int> bowls = [];
  List<Skewer> reducedSkewers = reduce(skewers);

  //map single items and store combinations in a separate list
  Map<String, int> bowlByFruit = {};
  List<Skewer> combinations = [];
  for (int i = 0; i < skewers.length; i++) {
    try {
      bowlByFruit.addEntries([reducedSkewers[i].getMapEntry()]);
    } on MapManyToManyException {
      combinations.add(reducedSkewers[i]);
    }
  }

  try {
    //assign pairs O(n)
    for (int i = 0; i < targetFruits.length; i++) {
      //assign simple pairs
      if (bowlByFruit.containsKey(targetFruits[i])) {
        bowls.add(bowlByFruit.putIfAbsent(
            targetFruits[i], () => throw "No bowl value"));
        targetFruits.removeAt(i);
        //do not skip the next item
        i--;
      }
      //try to assign multiple pairs
      else {
        //O(n/2)
        for (int j = 0; j < combinations.length; j++) {
          //test if targetFruit can be find in skewer, if not, fruit is not noted
          //more combinations, lesser runtime complexity.
          // Lesser combinations, more runtime complexity
          //but the current loop has a lesser runtime complexity
          if (combinations[j].fruits.contains(targetFruits[i])) {
            //test if every fruit is in the targetFruits
            //more combinations, lesser runtime complexity.
            // Lesser combinations, more runtime complexity
            //but the current loop has a lesser runtime complexity
            combinations[j].fruits.forEach((fruit) {
              int targetFruitsLength = targetFruits.length;
              //remove matching fruits
              targetFruits.removeWhere((targetFruit) => fruit == targetFruit);
              //if not element is removed,no targetFruit not in group combination
              if (targetFruitsLength == targetFruits.length) {
                throw "unsolvable: $fruit is in a group combination but not wanted in the final skewer";
              }
            });
            //add numbers
            bowls.addAll(combinations[j].bowlNumbers);
            //do not skip the next item
            i--;
            break; //inner loop
          }
        }
      }
    }

    //handling if target fruit(s) was not seen on skewers
    if (targetFruits.isNotEmpty) {
      //collect noted bowls numbers
      List<int> notedBowls = [];
      notedBowls.addAll(bowlByFruit.values);
      combinations.forEach((combination) {
        notedBowls.addAll(combination.bowlNumbers);
      });
      //check if the number of unknown fruits is equal to the target fruits
      if (targetFruits.length == nFruits - notedBowls.length) {
        List<int> unnotedBowls = [];
        for (int i = 1; i <= nFruits; i++) {
          //bowl not noted
          if (!notedBowls.contains(i)) unnotedBowls.add(i);
        }
        bowls.addAll(unnotedBowls);
        //for analysis of clearly assignable pairs
        if (targetFruits.length == 1) {
          bowlByFruit.putIfAbsent(targetFruits[0], () => unnotedBowls[0]);
        } else {
          combinations.add(Skewer(unnotedBowls, targetFruits));
        }
        targetFruits = [];
      } else {
        throw "unsolvable: there are ${targetFruits.length} fruits that are wanted and not seen on a skewer, but ${nFruits - notedBowls.length} unknown fruits in total";
      }
    }
  } catch (e) {
    throw e;
  } finally {
    //analysis
    print("One to one combinations: $bowlByFruit");
    print("Many to many combinations: $combinations");
  }
  return bowls;
}

//O=(m^2)*O(cutOverlap()) of for loops (i = j cuts runtime in half O=1/2(m^2)), m=skwers => ignoring insert/removeAt
List<Skewer> reduce(List<Skewer> skewers) {
  for (int i = 0; i < skewers.length; i++) {
    //j = i + 1 because on pos i is the current item
    for (int j = i + 1; j < skewers.length; j++) {
      Skewer overlapSkewer = skewers[i].cutOverlap(skewers[j]);
      //remove empty skewer
      //if empty, the origin skewers cannot be empty
      if (overlapSkewer.isNotEmpty) {
        skewers.insert(i, overlapSkewer);
        //if overlapSkewer is placed after the second Skewer (i > j)
        //check for the j position

        //both skewers empty
        if (skewers[i + 1].isEmpty && skewers[i > j ? j : j + 1].isEmpty) {
          skewers.removeAt(i + 1);
          skewers.removeAt(j);
          //go one step back to check element on the new position
          //(only one step back necessary because first empty position is replaced with the cut item)
          j--;
        }
        //first skewer empty
        else if (skewers[i + 1].isEmpty) {
          skewers.removeAt(i + 1);
        }
        //second skewer empty
        //if overlapSkewer is placed after the second Skewer (i > j), check for the j position
        else if (skewers[i > j ? j : j + 1].isEmpty) {
          skewers.removeAt(i > j ? j : j + 1);
        }
        //no skewer empty, go one step further
        //(since one item was added to the list, not increasing j would result in a comparison of the just compared skewer)
        else {
          j++;
        }
      }
    }
  }
  return skewers;
}

List<String> extractFruitsFrom(String text) {
  List<String> fruits = text.split(" ");
  fruits.removeWhere((element) => element.isEmpty); //remove empty lines
  return fruits;
}
