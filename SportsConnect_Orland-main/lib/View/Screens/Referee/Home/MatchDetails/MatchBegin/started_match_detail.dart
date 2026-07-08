import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/view_score_referee.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/controllers/scoreboard_controller.dart';

class StartedMatchDetail extends StatelessWidget {
  StartedMatchDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<RefereeMatchController>();
    final match = matchController.currentMatch.value!;
    
    // Inject Controller
    final ScoreboardController scoreboard = Get.put(ScoreboardController(match: match));

    String team1Name = match.player1Name ?? 'Local';
    String team2Name = match.player2Name ?? 'Visitante';

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: matchDetail,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: kblack2,
                ))
          ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Real-time Score Container
                Obx(() {
                  List<String> t1s = scoreboard.team1SetsScore.map((e) => e.toString()).toList();
                  List<String> t2s = scoreboard.team2SetsScore.map((e) => e.toString()).toList();
                  // We inject the current game into the array too, to be visible
                  t1s.add(scoreboard.currentTeam1Games.value.toString());
                  t2s.add(scoreboard.currentTeam2Games.value.toString());

                  return Show_Score_Container(
                    yinScores: t1s,
                    dylnScores: t2s,
                  );
                }),

                MyText(
                  paddingTop: 15,
                  text: 'Tiempo Jugado',
                  size: 16,
                  weight: FontWeight.w600,
                  color: kblack2,
                  paddingBottom: 6,
                  textAlign: TextAlign.center,
                ),
                Obx(() => MyText(
                  text: scoreboard.formattedTimeText,
                  size: 24,
                  weight: FontWeight.w700,
                  color: kblack2,
                  paddingBottom: 5,
                  textAlign: TextAlign.center,
                )),
                
                Obx(() => MyText(
                  text: scoreboard.isTieBreak.value ? '¡Tie-Break Activo!' : 'Partido en Progreso',
                  size: 16,
                  weight: FontWeight.w600,
                  color: kblack2,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                )),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      teammates_name_container(
                        name: team1Name,
                        bgcolor: kgrey4,
                        textcolor: kgrey1,
                        isleft: true,
                      ),
                      teammates_name_container(
                        name: team2Name,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    // TEAM 1 ACTIONS
                    Expanded(
                      child: Column(
                        children: [
                          Obx(() => MyText(
                            text: scoreboard.getPointText(1), 
                            size: 40, 
                            weight: FontWeight.bold,
                            color: kpurple1,
                            paddingBottom: 15,
                            textAlign: TextAlign.center,
                          )),
                          GestureDetector(
                            onTap: () => scoreboard.addPoint(1),
                            child: members_property_container(textt: '+ Punto $team1Name'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    // TEAM 2 ACTIONS
                    Expanded(
                      child: Column(
                        children: [
                           Obx(() => MyText(
                            text: scoreboard.getPointText(2), 
                            size: 40, 
                            weight: FontWeight.bold,
                            color: kpurple1,
                            paddingBottom: 15,
                            textAlign: TextAlign.center,
                          )),
                          GestureDetector(
                            onTap: () => scoreboard.addPoint(2),
                            child: members_property_container(textt: '+ Punto $team2Name'),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () {
                      Get.defaultDialog(
                        title: "Declarar Empate",
                        middleText: "¿Finalizar el partido por falta de tiempo y declararlo empate?",
                        textCancel: "Cancelar",
                        textConfirm: "Sí, finalizar",
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          Get.back(); // close dialog
                          scoreboard.endMatch(isDraw: true);
                        }
                      );
                    },
                    child: Text('Declarar Empate\n(Fin Tiempo)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: MyButton(
                    onTap: () {
                      Get.defaultDialog(
                        title: "Forzar Ganador",
                        middleText: "¿A quién declarar ganador manual y cerrar partido?",
                        content: Column(
                          children: [
                            ElevatedButton(onPressed: () {Get.back(); scoreboard.endMatch(winnerId: match.player1Id);}, child: Text("Ganó $team1Name")),
                            SizedBox(height: 10),
                            ElevatedButton(onPressed: () {Get.back(); scoreboard.endMatch(winnerId: match.player2Id);}, child: Text("Ganó $team2Name")),
                          ]
                        ),
                        textCancel: "Cancelar"
                      );
                    },
                    buttonText: 'Finalizar',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30)
        ],
      ),
    );
  }
}

class members_property_container extends StatefulWidget {
  final String textt;
  const members_property_container({
    super.key,
    required this.textt,
  });

  @override
  State<members_property_container> createState() =>
      _members_property_containerState();
}

class _members_property_containerState
    extends State<members_property_container> {
  bool selected = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = !selected;
        });
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? kpink : kgrey2),
            color: kwhite),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 35),
        child: Center(
            child: MyText(
          text: widget.textt,
          size: 14,
          weight: FontWeight.w500,
          color: selected ? kred : kblack2,
        )),
      ),
    );
  }
}

class teammates_name_container extends StatelessWidget {
  final String name;
  final Color? bgcolor, textcolor;
  final bool? isleft;
  const teammates_name_container({
    super.key,
    required this.name,
    this.bgcolor,
    this.textcolor,
    this.isleft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft:
                      isleft == true ? Radius.circular(12) : Radius.circular(0),
                  bottomLeft:
                      isleft == true ? Radius.circular(12) : Radius.circular(0),
                  topRight: isleft == false
                      ? Radius.circular(12)
                      : Radius.circular(0),
                  bottomRight: isleft == false
                      ? Radius.circular(12)
                      : Radius.circular(0)),
              color: bgcolor ?? kpurple1),
          child: Center(
            child: MyText(
              text: name,
              color: textcolor ?? kwhite,
              size: 16,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
