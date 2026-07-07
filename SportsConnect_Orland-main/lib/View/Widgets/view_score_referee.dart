import 'package:flutter/material.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class Show_Score_Container extends StatelessWidget {
  final List<String> yinScores;
  final List<String> dylnScores;

  const Show_Score_Container({
    super.key,
    required this.yinScores,
    required this.dylnScores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kgrey2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                show_score(name: 'Yin', scores: yinScores),
                const SizedBox(
                  height: 10,
                ),
                show_score(name: 'Dyln', scores: dylnScores),
              ],
            ),
          ),
          Container(
            height: 75,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              color: kpurple1,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyText(
                  text: yinScores.last,
                  paddingRight: 10,
                  color: kwhite,
                  size: 16,
                  weight: FontWeight.w600,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyText(
                  text: dylnScores.last,
                  paddingRight: 10,
                  color: kwhite,
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class show_score extends StatefulWidget {
  final String name;
  final List<String> scores;

  const show_score({super.key, required this.name, required this.scores});

  @override
  State<show_score> createState() => _show_scoreState();
}

class _show_scoreState extends State<show_score> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = !selected;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (selected)
            Row(
              children: [
                const SizedBox(
                  width: 5,
                ),
                Image.asset(
                  Assets.imagesSelectedarrow,
                  width: 6,
                  height: 11,
                ),
                MyText(
                  text: widget.name,
                  paddingLeft: 5,
                  color: kpurple1,
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ],
            )
          else
            MyText(
              text: widget.name,
              paddingLeft: 10,
              color: kgrey1,
              size: 16,
              weight: FontWeight.w600,
            ),
          Row(
            children: widget.scores
                .map((score) => MyText(
                      text: score,
                      paddingRight: 10,
                      color: selected ? kpurple1 : kgrey1,
                      size: 16,
                      weight: FontWeight.w600,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
