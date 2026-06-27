#!/usr/bin/env python3
import os
import uuid

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
app_dir = os.path.join(root, "DeezSpacesaver")
test_dir = os.path.join(root, "DeezSpacesaverTests")

swift_files = []
for base, _, files in os.walk(app_dir):
    for f in sorted(files):
        if f.endswith(".swift"):
            rel = os.path.relpath(os.path.join(base, f), root)
            swift_files.append(rel)

test_files = [
    f"DeezSpacesaverTests/{f}"
    for f in sorted(os.listdir(test_dir))
    if f.endswith(".swift")
]


def uid():
    return uuid.uuid4().hex[:24].upper()


project_uid = uid()
target_uid = uid()
test_target_uid = uid()
project_config_list = uid()
target_config_list = uid()
test_config_list = uid()
project_debug = uid()
project_release = uid()
target_debug = uid()
target_release = uid()
test_debug = uid()
test_release = uid()
sources_phase = uid()
resources_phase = uid()
frameworks_phase = uid()
test_sources_phase = uid()
test_frameworks_phase = uid()
test_dependency = uid()
dep_proxy = uid()
product_ref = uid()
test_product_ref = uid()
app_group = uid()
test_group = uid()
products_group = uid()
main_group = uid()
entitlements_ref = uid()
info_plist_ref = uid()
assets_ref = uid()
assets_build = uid()

file_refs = {sf: uid() for sf in swift_files}
build_files = {sf: uid() for sf in swift_files}
test_file_refs = {tf: uid() for tf in test_files}
test_build_files = {tf: uid() for tf in test_files}

groups = {}
groups["DeezSpacesaver"] = {"id": app_group, "path": "DeezSpacesaver"}
group_children = {app_group: []}


def ensure_group(path_parts):
    current = app_group
    built = "DeezSpacesaver"
    for part in path_parts:
        built = f"{built}/{part}"
        if built not in groups:
            gid = uid()
            groups[built] = {"id": gid, "path": part}
            group_children[gid] = []
            group_children[current].append((gid, part))
        current = groups[built]["id"]
    return current


for sf in swift_files:
    parts = sf.split("/")
    if len(parts) > 2:
        parent = ensure_group(parts[1:-1])
        group_children[parent].append((file_refs[sf], os.path.basename(sf)))
    else:
        group_children[app_group].append((file_refs[sf], os.path.basename(sf)))

group_children[app_group].extend([
    (assets_ref, "Assets.xcassets"),
    (entitlements_ref, "DeezSpacesaver.entitlements"),
    (info_plist_ref, "Info.plist"),
])

lines = [
    "// !$*UTF8*$!",
    "{",
    "\tarchiveVersion = 1;",
    "\tclasses = {};",
    "\tobjectVersion = 56;",
    "\tobjects = {",
    "",
    "/* Begin PBXBuildFile section */",
]
for sf in swift_files:
    lines.append(
        f"\t\t{build_files[sf]} /* {os.path.basename(sf)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[sf]} /* {os.path.basename(sf)} */; }};"
    )
lines.append(
    f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};"
)
for tf in test_files:
    lines.append(
        f"\t\t{test_build_files[tf]} /* {os.path.basename(tf)} in Sources */ = {{isa = PBXBuildFile; fileRef = {test_file_refs[tf]} /* {os.path.basename(tf)} */; }};"
    )
lines.append("/* End PBXBuildFile section */")
lines.append("")
lines.append("/* Begin PBXFileReference section */")
lines.append(
    f"\t\t{product_ref} /* DeezSpacesaver.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DeezSpacesaver.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
lines.append(
    f"\t\t{test_product_ref} /* DeezSpacesaverTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = DeezSpacesaverTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
for sf in swift_files:
    lines.append(
        f"\t\t{file_refs[sf]} /* {os.path.basename(sf)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {os.path.basename(sf)}; sourceTree = \"<group>\"; }};"
    )
lines.extend([
    f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};",
    f"\t\t{entitlements_ref} /* DeezSpacesaver.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = DeezSpacesaver.entitlements; sourceTree = \"<group>\"; }};",
    f"\t\t{info_plist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};",
])
for tf in test_files:
    lines.append(
        f"\t\t{test_file_refs[tf]} /* {os.path.basename(tf)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {os.path.basename(tf)}; sourceTree = \"<group>\"; }};"
    )
lines.append("/* End PBXFileReference section */")
lines.append("")
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.extend([
    f"\t\t{frameworks_phase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
    f"\t\t{test_frameworks_phase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
    "/* End PBXFrameworksBuildPhase section */",
    "",
    "/* Begin PBXGroup section */",
    f"\t\t{main_group} = {{isa = PBXGroup; children = ({app_group} /* DeezSpacesaver */, {test_group} /* DeezSpacesaverTests */, {products_group} /* Products */); sourceTree = \"<group>\"; }};",
    f"\t\t{products_group} /* Products */ = {{isa = PBXGroup; children = ({product_ref} /* DeezSpacesaver.app */, {test_product_ref} /* DeezSpacesaverTests.xctest */); name = Products; sourceTree = \"<group>\"; }};",
])

for key in sorted(groups.keys()):
    g = groups[key]
    children = group_children.get(g["id"], [])
    child_str = ", ".join(f"{ref} /* {name} */" for ref, name in children)
    name_attr = "" if key == "DeezSpacesaver" else f'name = {g["path"]}; '
    lines.append(
        f'\t\t{g["id"]} /* {g["path"]} */ = {{isa = PBXGroup; children = ({child_str}); {name_attr}path = {g["path"]}; sourceTree = "<group>"; }};'
    )

test_children = ", ".join(
    f"{test_file_refs[tf]} /* {os.path.basename(tf)} */" for tf in test_files
)
lines.extend([
    f"\t\t{test_group} /* DeezSpacesaverTests */ = {{isa = PBXGroup; children = ({test_children}); path = DeezSpacesaverTests; sourceTree = \"<group>\"; }};",
    "/* End PBXGroup section */",
    "",
    "/* Begin PBXNativeTarget section */",
    f"\t\t{target_uid} /* DeezSpacesaver */ = {{isa = PBXNativeTarget; buildConfigurationList = {target_config_list}; buildPhases = ({sources_phase} /* Sources */, {frameworks_phase} /* Frameworks */, {resources_phase} /* Resources */); buildRules = (); dependencies = (); name = DeezSpacesaver; productName = DeezSpacesaver; productReference = {product_ref}; productType = \"com.apple.product-type.application\"; }};",
    f"\t\t{test_target_uid} /* DeezSpacesaverTests */ = {{isa = PBXNativeTarget; buildConfigurationList = {test_config_list}; buildPhases = ({test_sources_phase} /* Sources */, {test_frameworks_phase} /* Frameworks */); buildRules = (); dependencies = ({test_dependency} /* PBXTargetDependency */); name = DeezSpacesaverTests; productName = DeezSpacesaverTests; productReference = {test_product_ref}; productType = \"com.apple.product-type.bundle.unit-test\"; }};",
    "/* End PBXNativeTarget section */",
    "",
    "/* Begin PBXProject section */",
    f"\t\t{project_uid} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500; TargetAttributes = {{{target_uid} = {{CreatedOnToolsVersion = 15.0; }}; {test_target_uid} = {{CreatedOnToolsVersion = 15.0; TestTargetID = {target_uid}; }}; }}; }}; buildConfigurationList = {project_config_list}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main_group}; productRefGroup = {products_group}; projectDirPath = \"\"; projectRoot = \"\"; targets = ({target_uid} /* DeezSpacesaver */, {test_target_uid} /* DeezSpacesaverTests */); }};",
    "/* End PBXProject section */",
    "",
    "/* Begin PBXResourcesBuildPhase section */",
    f"\t\t{resources_phase} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assets_build} /* Assets.xcassets in Resources */); runOnlyForDeploymentPostprocessing = 0; }};",
    "/* End PBXResourcesBuildPhase section */",
    "",
    "/* Begin PBXSourcesBuildPhase section */",
])
src_files = ", ".join(
    f"{build_files[sf]} /* {os.path.basename(sf)} in Sources */" for sf in swift_files
)
lines.append(
    f"\t\t{sources_phase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({src_files}); runOnlyForDeploymentPostprocessing = 0; }};"
)
test_src = ", ".join(
    f"{test_build_files[tf]} /* {os.path.basename(tf)} in Sources */" for tf in test_files
)
lines.extend([
    f"\t\t{test_sources_phase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({test_src}); runOnlyForDeploymentPostprocessing = 0; }};",
    "/* End PBXSourcesBuildPhase section */",
    "",
    "/* Begin PBXContainerItemProxy section */",
    f"\t\t{dep_proxy} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {project_uid}; proxyType = 1; remoteGlobalIDString = {target_uid}; remoteInfo = DeezSpacesaver; }};",
    "/* End PBXContainerItemProxy section */",
    "",
    "/* Begin PBXTargetDependency section */",
    f"\t\t{test_dependency} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {target_uid}; targetProxy = {dep_proxy}; }};",
    "/* End PBXTargetDependency section */",
    "",
    "/* Begin XCBuildConfiguration section */",
])

common_swift = "SWIFT_VERSION = 5.9; MACOSX_DEPLOYMENT_TARGET = 14.0;"
app_debug = (
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; "
    "CODE_SIGN_ENTITLEMENTS = DeezSpacesaver/DeezSpacesaver.entitlements; "
    "CODE_SIGN_STYLE = Automatic; COMBINE_HIDPI_IMAGES = YES; CURRENT_PROJECT_VERSION = 1; "
    "DEVELOPMENT_TEAM = \"\"; ENABLE_HARDENED_RUNTIME = YES; ENABLE_TESTABILITY = YES; "
    "GENERATE_INFOPLIST_FILE = NO; "
    "INFOPLIST_FILE = DeezSpacesaver/Info.plist; "
    'LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks"); '
    "MARKETING_VERSION = 1.0.0; PRODUCT_BUNDLE_IDENTIFIER = io.worldbuild.DeezSpacesaver; "
    'PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG = 1; '
    + common_swift
)
app_release = app_debug.replace('SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG = 1; ', "SWIFT_COMPILATION_MODE = wholemodule; ")

lines.extend([
    f"\t\t{project_debug} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf; GCC_DYNAMIC_NO_PIC = NO; GCC_OPTIMIZATION_LEVEL = 0; GCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\"); MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE; ONLY_ACTIVE_ARCH = YES; SDKROOT = macosx; {common_swift} }}; name = Debug; }};",
    f"\t\t{project_release} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\"; SDKROOT = macosx; {common_swift} }}; name = Release; }};",
    f"\t\t{target_debug} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{{app_debug}}}; name = Debug; }};",
    f"\t\t{target_release} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{{app_release}}}; name = Release; }};",
    f"\t\t{test_debug} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{BUNDLE_LOADER = \"$(TEST_HOST)\"; CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = io.worldbuild.DeezSpacesaverTests; PRODUCT_NAME = \"$(TARGET_NAME)\"; TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/DeezSpacesaver.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DeezSpacesaver\"; {common_swift} }}; name = Debug; }};",
    f"\t\t{test_release} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{BUNDLE_LOADER = \"$(TEST_HOST)\"; CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = io.worldbuild.DeezSpacesaverTests; PRODUCT_NAME = \"$(TARGET_NAME)\"; TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/DeezSpacesaver.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DeezSpacesaver\"; {common_swift} }}; name = Release; }};",
    "/* End XCBuildConfiguration section */",
    "",
    "/* Begin XCConfigurationList section */",
    f"\t\t{project_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({project_debug} /* Debug */, {project_release} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
    f"\t\t{target_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({target_debug} /* Debug */, {target_release} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
    f"\t\t{test_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({test_debug} /* Debug */, {test_release} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
    "/* End XCConfigurationList section */",
    "\t};",
    f"\trootObject = {project_uid} /* Project object */;",
    "}",
])

proj_path = os.path.join(root, "DeezSpacesaver.xcodeproj/project.pbxproj")
with open(proj_path, "w") as f:
    f.write("\n".join(lines) + "\n")

scheme_dir = os.path.join(root, "DeezSpacesaver.xcodeproj/xcshareddata/xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
scheme_path = os.path.join(scheme_dir, "DeezSpacesaver.xcscheme")
with open(scheme_path, "w") as f:
    f.write(f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_uid}" BuildableName="DeezSpacesaver.app" BlueprintName="DeezSpacesaver" ReferencedContainer="container:DeezSpacesaver.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test_target_uid}" BuildableName="DeezSpacesaverTests.xctest" BlueprintName="DeezSpacesaverTests" ReferencedContainer="container:DeezSpacesaver.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_uid}" BuildableName="DeezSpacesaver.app" BlueprintName="DeezSpacesaver" ReferencedContainer="container:DeezSpacesaver.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
""")

print(f"Wrote {proj_path}")
