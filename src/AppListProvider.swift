/*
 * Copyright (c) 2020 Jose Pereira <onaips@gmail.com>.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import FileWatcher
import Fuse

/**
 * Provide a list of launcheable apps for the OS
 */
class AppListProvider: ListProvider {

    var appDirDict = [String: Bool]()

    var appList = [URL]()

    init() {
        let applicationDir = NSSearchPathForDirectoriesInDomains(
            .applicationDirectory, .localDomainMask, true)[0]

        // Catalina moved default applications under a different mask.
        let systemApplicationDir = NSSearchPathForDirectoriesInDomains(
            .applicationDirectory, .systemDomainMask, true)[0]

        // appName to dir recursivity key/valye dict
        appDirDict[applicationDir] = true
        appDirDict[systemApplicationDir] = true
        appDirDict["/System/Library/CoreServices/"] = false
        // Folders in path
        appDirDict["/usr/local/sbin"] = true
        appDirDict["/usr/local/bin"] = true
        appDirDict["/System/Cryptexes/App/usr/bin"] = true
        appDirDict["/usr/bin"] = true
        appDirDict["/bin"] = true
        appDirDict["/usr/sbin"] = true
        appDirDict["/sbin"] = true
        appDirDict["/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin"] = true
        appDirDict["/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin"] = true
        appDirDict["/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"] = true
        appDirDict["/Library/Apple/usr/bin"] = true
        appDirDict["/Library/TeX/texbin"] = true
        appDirDict["~/.local/bin"] = true

        initFileWatch(Array(appDirDict.keys))
        updateAppList()
    }

    func initFileWatch(_ dirs: [String]) {
        let filewatcher = FileWatcher(dirs)
        filewatcher.callback = {_ in
            self.updateAppList()
        }
        filewatcher.start()
    }

    func updateAppList() {
        var newAppList = [URL]()
        appDirDict.keys.forEach { path in
            let urlPath = URL(fileURLWithPath: path, isDirectory: true)
            let list = getAppList(urlPath, recursive: appDirDict[path]!)
            newAppList.append(contentsOf: list)
        }
        appList = newAppList
    }

    func getAppList(_ appDir: URL, recursive: Bool = true) -> [URL] {
        var list = [URL]()
        let fileManager = FileManager.default

        do {
            let subs = try fileManager.contentsOfDirectory(atPath: appDir.path)

            for sub in subs {
                let dir = appDir.appendingPathComponent(sub)

                if dir.pathExtension == "app" {
                    list.append(dir)
                // Doesn't resolve symlinked executables and errors because "dmenu-mac isn't allowed to open documents in terminal"
                } else if fileManager.isExecutableFile(atPath: dir.relativePath) {
                    list.append(dir)
                } else if dir.hasDirectoryPath && recursive {
                    list.append(contentsOf: self.getAppList(dir))
                }
            }
        } catch {
            NSLog("Error on getAppList: %@", error.localizedDescription)
        }
        return list
    }

    func get() -> [ListItem] {
        return appList.map({ListItem(name: $0.deletingPathExtension().lastPathComponent, data: $0)})
    }

    func doAction(item: ListItem) {
        guard let app: URL = item.data as? URL else {
            NSLog("Cannot do action on item \(item.name)")
            return
        }
        DispatchQueue.main.async {
            NSWorkspace.shared.open(app)
        }
    }
}
