import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart'; //You can also import the browser version
import 'package:web3dart/web3dart.dart';
import 'dart:math';

const String privateKey =
    '0ef2e2572322c52233405c9338c7e56a43fcfc6b04b105202827b8ad08d9f0f4';
const String rpcUrl = 'http://127.0.0.1:7545';

Future<void> main() async {
  try {
    // start a client we can use to send transactions
    final client = Web3Client(rpcUrl, Client());

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;

    print(address.hexEip55);
    print('I have gotten here');
    print(await client.getBalance(address));

    await client.sendTransaction(
      credentials,
      Transaction(
        to: EthereumAddress.fromHex(
            '0x288B454820Ad33dE60aE2CF2AEf338be3c093270'),
        gasPrice: EtherAmount.inWei(BigInt.one),
        maxGas: 100000,
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
      ),
    );

    await client.dispose();
    print('I AM DONE WAITING!!!!');
    runApp(const MyApp());
  } catch (e) {
    print(e.toString());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'CBT on Blockchain',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(
          title: "My BlockChain",
        ));
  }
}

class TestTestPage extends StatelessWidget {
  const TestTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ethClient = Web3Client("http://127.0.0.1:7545", Client());

  Credentials credentials = EthPrivateKey.fromHex(
      "0ef2e2572322c52233405c9338c7e56a43fcfc6b04b105202827b8ad08d9f0f4");

  List<String> questions = [];
  Map<String, List<String>> questionOptions = {};

  @override
  // void initState() {
  //   super.initState();
  //   const String privateKey =
  //       '0ef2e2572322c52233405c9338c7e56a43fcfc6b04b105202827b8ad08d9f0f4';
  //   const String rpcUrl = 'http://localhost:7545';
  //   final client = Web3Client(rpcUrl, Client());

  //   final credentials = EthPrivateKey.fromHex(privateKey);
  //   final address = credentials.address;

  //   print(address.hexEip55);
  //   print(client.getBalance(address));
  //   // print(await client.getBalance(address));
  //   // print(ethClient);
  //   // print(ethClient.getNetworkId().then((value) => print("value ${value}")));

  //   // credentials.extractAddress().then((address) {
  //   //   print(address);
  //   //   print(ethClient.getNetworkId().then((value) {
  //   //     print('this is value: $value');
  //   //   }));

  //   //   // EtherAmount balance = ethClient.getBalance(credentials.address);

  //   //   // ethClient.getBalance(address).then((balance) {
  //   //   //   print(balance);
  //   //   //   print(balance.getValueInUnit(EtherUnit.ether));
  //   //   // });
  //   // });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please wait, fetching random questions.'),
                  ),
                );

                String abiCode = await rootBundle.loadString("assets/abi.json");

                EthereumAddress accountAddress =
                    await credentials.extractAddress();
                final contract = DeployedContract(
                    ContractAbi.fromJson(abiCode, 'Storage'),
                    EthereumAddress.fromHex(
                        "0x288B454820Ad33dE60aE2CF2AEf338be3c093270"));

                final sendFunction =
                    contract.function('retrieveRandomQuestions');

                ContractEvent event = contract.event("QuestionHashes");

                void getQuestion(
                    List<BigInt> questionHashes, BigInt randomNumber) {
                  final sendFunction = contract.function('retrieveQuestion');

                  ethClient.sendTransaction(
                    credentials,
                    Transaction.callContract(
                      contract: contract,
                      function: sendFunction,
                      parameters: [questionHashes, randomNumber],
                    ),
                  );
                }

                ethClient
                    .events(
                        FilterOptions.events(contract: contract, event: event))
                    .take(1)
                    .listen((evnt) {
                  var data = event.decodeResults(evnt.topics!, evnt.data!);
                  String rawQuestionHashes = data[1];
                  List<String> questionHashesString =
                      rawQuestionHashes.split(" ");
                  List<BigInt> questionHashes = [];
                  for (String questionHashString in questionHashesString) {
                    if (questionHashString.isNotEmpty) {
                      questionHashes.add(BigInt.tryParse(questionHashString)!);
                    }
                  }

                  Random random = Random();
                  BigInt randomNumber = BigInt.from(random.nextInt(10000000));

                  print(questionHashes[0]);
                  print(randomNumber);

                  getQuestion(questionHashes, randomNumber);
                });

                ContractEvent event1 = contract.event("QuestionRetrieved");

                ethClient
                    .events(
                        FilterOptions.events(contract: contract, event: event1))
                    .take(1)
                    .listen((evnt) {
                  var data = event1.decodeResults(evnt.topics!, evnt.data!);
                  List<String> rawQuestions = data[2].split("---");
                  for (String rawQuestion in rawQuestions) {
                    if (rawQuestion.isNotEmpty) {
                      List<String> rawQuestionParts = rawQuestion.split("--");
                      questions.add(rawQuestionParts[4]);
                      questionOptions[rawQuestionParts[4]] =
                          rawQuestionParts.sublist(0, 4);
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestPage(
                        questions: questions,
                        questionOptions: questionOptions,
                        contract: contract,
                        credentials: credentials,
                        ethClient: ethClient,
                        accountAddress: accountAddress,
                      ),
                    ),
                  );
                });

                await ethClient.sendTransaction(
                  credentials,
                  Transaction(
                    to: EthereumAddress.fromHex(
                        '0x288B454820Ad33dE60aE2CF2AEf338be3c093270'),
                    gasPrice: EtherAmount.inWei(BigInt.one),
                    maxGas: 100000,
                    value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
                  ),
                );

                print('I got here');
                // ethClient.sendTransaction(
                //   credentials,
                //   Transaction(
                //     to: EthereumAddress.fromHex(
                //         '0x288B454820Ad33dE60aE2CF2AEf338be3c093270'),
                //     gasPrice: EtherAmount.inWei(BigInt.one),
                //     maxGas: 100000,
                //     value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
                //   ),
                // );
                // ethClient.sendTransaction(
                //   credentials,
                //   Transaction.callContract(
                //     contract: contract,
                //     function: sendFunction,
                //     parameters: [],
                //   ),
                // );
                //     .then((transactionHash) {
                //   print(transactionHash);
                //   ethClient.getTransactionByHash(transactionHash).then((value) {
                //     print("This is the transaction value ${value.transactionIndex}");
                //   });
                // });
              },
              child: const Text("Start Test"),
            )
          ],
        ),
      ),
    );
  }
}

class TestPage extends StatefulWidget {
  TestPage(
      {Key? key,
      required this.questions,
      required this.questionOptions,
      required this.contract,
      required this.credentials,
      required this.ethClient,
      required this.accountAddress})
      : super(key: key);

  List<String> questions = [];
  Map<String, List<String>> questionOptions = {};
  DeployedContract contract;
  Credentials credentials;
  Web3Client ethClient;
  EthereumAddress accountAddress;
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<dynamic> choosenOptions = [];

  Color getButtonColor(index, option) {
    if (choosenOptions[index] == option) {
      return Colors.greenAccent;
    }
    return Colors.blueAccent;
  }

  void chooseButton(index, option) {
    setState(() {
      choosenOptions[index] = option;
    });
  }

  Widget getQuizWidget(String question, int index) {
    List<String> thisQuestionOptions = widget.questionOptions[question]!;
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.indigo,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 127, 209, 235),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, 1), // changes position of shadow
                ),
              ],
            ),
            child: Text(question),
          ),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          getButtonColor(index, 0)),
                    ),
                    child: Text(thisQuestionOptions[0]),
                    onPressed: () {
                      chooseButton(index, 0);
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          getButtonColor(index, 1)),
                    ),
                    child: Text(thisQuestionOptions[1]),
                    onPressed: () {
                      chooseButton(index, 1);
                    },
                  ),
                ),
              )
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          getButtonColor(index, 2)),
                    ),
                    child: Text(thisQuestionOptions[2]),
                    onPressed: () {
                      chooseButton(index, 2);
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          getButtonColor(index, 3)),
                    ),
                    child: Text(thisQuestionOptions[3]),
                    onPressed: () {
                      chooseButton(index, 3);
                    },
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (choosenOptions.isEmpty) {
      for (var inQuestion in widget.questions) {
        choosenOptions.add(null);
      }
    }
    print(choosenOptions);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Test'),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.questions.length,
              itemBuilder: (BuildContext context, int index) {
                return getQuizWidget(widget.questions[index], index);
              }),
        ),
        Center(
          child: ElevatedButton(
            child: const Text("Submit"),
            onPressed: () {
              bool allDone = true;
              print(choosenOptions);
              for (var choosen in choosenOptions) {
                if (choosen == null) {
                  allDone = false;
                }
              }
              if (!allDone) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please choose for all questions before submitting!'),
                  ),
                );
              } else {
                final sendFunction = widget.contract.function('checkAnswer');

                List<BigInt> choosenOptionsBig = [];
                for (int choosenOption in choosenOptions) {
                  choosenOptionsBig.add(BigInt.from(choosenOption + 1));
                }

                widget.ethClient.sendTransaction(
                  widget.credentials,
                  Transaction.callContract(
                    contract: widget.contract,
                    function: sendFunction,
                    parameters: [choosenOptionsBig],
                  ),
                );

                ContractEvent event = widget.contract.event("AnswerChecked");
                BigInt marks = BigInt.from(0);

                widget.ethClient
                    .events(FilterOptions.events(
                        contract: widget.contract, event: event))
                    .take(1)
                    .listen((evnt) {
                  var data = event.decodeResults(evnt.topics!, evnt.data!);
                  marks = data[1];

                  final sendFunction1 = widget.contract.function('getRank');

                  widget.ethClient.sendTransaction(
                    widget.credentials,
                    Transaction.callContract(
                      contract: widget.contract,
                      function: sendFunction1,
                      parameters: [],
                    ),
                  );
                });

                ContractEvent event1 = widget.contract.event("RankObtained");

                widget.ethClient
                    .events(FilterOptions.events(
                        contract: widget.contract, event: event1))
                    .take(1)
                    .listen((evnt) {
                  var data = event1.decodeResults(evnt.topics!, evnt.data!);

                  BigInt rank = data[1];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Result(
                          credentials: widget.credentials,
                          marks: marks,
                          accountAddress: widget.accountAddress,
                          rank: rank),
                    ),
                  );
                });
              }
            },
          ),
        )
      ]),
    );
  }
}

class Result extends StatelessWidget {
  Result({
    Key? key,
    required this.credentials,
    required this.marks,
    required this.accountAddress,
    required this.rank,
  }) : super(key: key);

  Credentials credentials;
  BigInt marks;
  EthereumAddress accountAddress;
  BigInt rank;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Result"),
        ),
        body: Column(
          children: [
            Center(
              child: Text(accountAddress.hex),
            ),
            Center(
              child: Text("Marks: " + marks.toString()),
            ),
            Center(
              child: Text("Rank: " + rank.toString()),
            ),
          ],
        ));
  }
}
