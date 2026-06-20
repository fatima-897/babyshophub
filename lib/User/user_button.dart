import 'package:flutter/material.dart';

class UserButton extends StatelessWidget {
  final String btntext; //string stype variable
  final void Function()? ontap;
  const UserButton({super.key, required this.ontap, required this.btntext});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF3E2723),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            btntext,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
