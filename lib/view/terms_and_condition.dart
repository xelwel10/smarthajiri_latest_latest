import 'package:flutter/material.dart';

class TermsAndPoliciesPage extends StatelessWidget {
  const TermsAndPoliciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "XelwelHr | Terms & Policies",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 2,
                          color: Colors.white54,
                          width: 150,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PolicySection(
                          icon: Icons.wifi,
                          title: "Internet Access Permission",
                          description:
                              "Purpose: To ensure the system can communicate with the server and sync data in real-time, internet access is required.",
                          requirement:
                              "Requirement: Users must have internet access enabled for the system to perform tasks like data synchronization, file uploads, and receiving updates.",
                          usage:
                              "Usage: Internet connectivity will be used only for system operations and data transfer as needed for the user's work activities.",
                        ),
                        SizedBox(height: 20),
                        PolicySection(
                          icon: Icons.location_on,
                          title: "Location Permission",
                          description:
                              "Purpose: To ensure accurate tracking of office attendance, users are required to enable location permissions during office hours.",
                          requirement:
                              "Requirement: Users must allow location access to check in to the system. If location permission is not granted, users will not be able to complete the check-in process.",
                          usage:
                              "Usage: The location data is used solely for verifying attendance and ensuring users are within the office premises during check-in.",
                        ),
                        SizedBox(height: 20),
                        PolicySection(
                          icon: Icons.attach_file,
                          title: "File Permission",
                          description:
                              "Purpose: To allow users to attach and upload necessary files for work-related tasks, file permission must be enabled.",
                          requirement:
                              "Requirement: Users must enable file access permissions to upload files. Without this permission, the upload functionality will be disabled, preventing users from attaching files to the system.",
                          usage:
                              "Usage: The files uploaded will be securely stored and used only for the intended work-related purposes.",
                        ),
                        SizedBox(height: 20),
                        PolicySection(
                          icon: Icons.notifications_active,
                          title: "Notifications Permission",
                          description:
                              "Purpose: To keep users informed about important updates, tasks, and reminders, notification permissions must be enabled.",
                          requirement:
                              "Requirement: Users are encouraged to allow notifications to stay updated on essential system alerts. Disabling notifications may result in missing critical information related to work activities.",
                          usage:
                              "Usage: Notifications will be used to alert users about new messages, deadlines, or other significant events related to their tasks.",
                        ),
                        SizedBox(height: 20),
                        PolicySection(
                          icon: Icons.storage,
                          title: "Data Storage Permission",
                          description:
                              "Purpose: To provide a seamless experience, certain data may need to be stored locally on the user's device.",
                          requirement:
                              "Requirement: Users must allow data storage permissions for the system to function optimally. If data storage permission is denied, some features may not work as intended.",
                          usage:
                              "Usage: Stored data will include necessary information to ensure smooth operation and will be managed in compliance with data privacy regulations.",
                        ),
                        SizedBox(height: 20),
                        PolicySection(
                          icon: Icons.camera_alt,
                          title: "Camera Permission",
                          description:
                              "Purpose: For functionalities that require photo or video capture, such as document scanning or identity verification, camera access is required.",
                          requirement:
                              "Requirement: Users must enable camera permissions to utilize features that need image or video capture. If camera permission is not granted, these features will be unavailable.",
                          usage:
                              "Usage: Images and videos captured will be used exclusively for the purpose for which they were taken and will be stored securely.",
                        ),
                        SizedBox(height: 40),
                        Text(
                          "Compliance",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color.fromARGB(255, 0, 185, 185),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "By using this system, users agree to the terms and policies stated above. Non-compliance with any of these permissions may limit the functionality of the system and hinder the user's ability to perform certain tasks. All data collected through these permissions will be handled with the utmost care, in accordance with our privacy policy and applicable laws.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String requirement;
  final String usage;

  const PolicySection({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.requirement = "",
    required this.usage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 40,
          color: const Color.fromARGB(255, 0, 185, 185),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 185, 185),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 5),
              if (requirement.isNotEmpty)
                Text(
                  requirement,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              const SizedBox(height: 10),
              Text(
                usage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
