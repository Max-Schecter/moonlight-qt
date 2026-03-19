#pragma once

#include <cstdint>
#include <string>

namespace macos_clipboard {
bool isAvailable();
std::uint64_t getChangeCount();
std::string getText();
void setText(const std::string& text);
}
