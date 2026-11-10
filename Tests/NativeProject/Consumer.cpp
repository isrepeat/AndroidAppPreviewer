#include <AndroidAppPreviewerPluginSdk/AndroidAppPreviewerPlugin.h>

#include <iostream>

int main() {
    using namespace universaldevkit::windows::androidapppreviewerpluginsdk;

    const auto* pluginAbi = xp_get_abi(android_app_previewer_plugin_abi_table_version);
    if (pluginAbi == nullptr || pluginAbi->version != android_app_previewer_plugin_abi_table_version || pluginAbi->size != sizeof(xp_plugin_abi)) {
        return 1;
    }
    if (pluginAbi->metadata.get_abi_version() != android_app_previewer_plugin_abi_version || xp_get_abi(0) != nullptr) {
        return 2;
    }
    std::cout << "Static PluginSDK consumer passed" << std::endl;
    return 0;
}