import re

path = "/Users/abrahamcastanedaquintero/tmp/BimboChallenge-iOSHack/app/BimboSIS/BimboSIS.xcodeproj/project.pbxproj"

with open(path, "r") as f:
    content = f.read()

# 1. PBXBuildFile
if "FirebaseStorage in Frameworks" not in content:
    build_file_section_end = content.find("/* End PBXBuildFile section */")
    insert = """\t\t287610012FAA53E000074B0A /* FirebaseStorage in Frameworks */ = {isa = PBXBuildFile; productRef = 287610022FAA53E000074B0A /* FirebaseStorage */; };
\t\t287610032FAA53E000074B0A /* FirebaseFirestore in Frameworks */ = {isa = PBXBuildFile; productRef = 287610042FAA53E000074B0A /* FirebaseFirestore */; };
\t\t287610052FAA53E000074B0A /* FirebaseVertexAI in Frameworks */ = {isa = PBXBuildFile; productRef = 287610062FAA53E000074B0A /* FirebaseVertexAI */; };
"""
    content = content[:build_file_section_end] + insert + content[build_file_section_end:]

# 2. PBXFrameworksBuildPhase
if "287610012FAA53E000074B0A" not in content:
    content = content.replace("2876004E2FAA53E000074B0A /* FirebaseAuth in Frameworks */,", "2876004E2FAA53E000074B0A /* FirebaseAuth in Frameworks */,\n\t\t\t\t287610012FAA53E000074B0A /* FirebaseStorage in Frameworks */,\n\t\t\t\t287610032FAA53E000074B0A /* FirebaseFirestore in Frameworks */,\n\t\t\t\t287610052FAA53E000074B0A /* FirebaseVertexAI in Frameworks */,")

# 3. PBXNativeTarget packageProductDependencies
if "287610022FAA53E000074B0A" not in content:
    content = content.replace("2876004D2FAA53E000074B0A /* FirebaseAuth */,", "2876004D2FAA53E000074B0A /* FirebaseAuth */,\n\t\t\t\t287610022FAA53E000074B0A /* FirebaseStorage */,\n\t\t\t\t287610042FAA53E000074B0A /* FirebaseFirestore */,\n\t\t\t\t287610062FAA53E000074B0A /* FirebaseVertexAI */,")

# 4. XCSwiftPackageProductDependency
if "FirebaseStorage" not in content.split("/* End XCSwiftPackageProductDependency section */")[0]:
    dep_end = content.find("/* End XCSwiftPackageProductDependency section */")
    insert = """\t\t287610022FAA53E000074B0A /* FirebaseStorage */ = {
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = 2876004A2FAA53E000074B0A /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
\t\t\tproductName = FirebaseStorage;
\t\t};
\t\t287610042FAA53E000074B0A /* FirebaseFirestore */ = {
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = 2876004A2FAA53E000074B0A /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
\t\t\tproductName = FirebaseFirestore;
\t\t};
\t\t287610062FAA53E000074B0A /* FirebaseVertexAI */ = {
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = 2876004A2FAA53E000074B0A /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
\t\t\tproductName = FirebaseVertexAI;
\t\t};
"""
    content = content[:dep_end] + insert + content[dep_end:]

with open(path, "w") as f:
    f.write(content)

print("Project patched.")
