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

import FileWatcher

/**
 * Provide a list of launcheable apps for the OS
 */
class AppListProvider: ListProvider {

    var appDirDict = [String: Bool]()

    var appList = [URL]()

    init() {
        let allMacosApplicationDir = NSSearchPathForDirectoriesInDomains(
            .allApplicationsDirectory, .allDomainsMask, true)

        var pathFolders: [String] = []

        // appName to dir recursivity key/valye dict
        for macosApplicationDir in allMacosApplicationDir {
            appDirDict[macosApplicationDir] = true
        }
        appDirDict["/System/Library/CoreServices/"] = false
        // Folders in path
        pathFolders.append(contentsOf: getContentsOfPathFiles(filepath: "/etc/paths"))
        pathFolders.append(contentsOf: getContentsOfPathFiles(filepath: "/etc/paths.d/"))
        pathFolders = pathFolders.filter {$0 != ""}
        for pathFolder in pathFolders {
            appDirDict[pathFolder] = false
        }
        // Hardcoded bin and applications folders
        appDirDict["/usr/local/sbin"] = false
        appDirDict[NSHomeDirectory()+"/.local/bin"] = false
        appDirDict["/nix/var/nix/profiles/default/bin"] = false
        appDirDict[NSHomeDirectory()+"/.nix-profile/bin"] = false
        appDirDict[NSHomeDirectory()+"/.nix-profile/Applications"] = true

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
        appList = Array(Set(newAppList))
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
                } else if dir.hasDirectoryPath && recursive {
                    list.append(contentsOf: self.getAppList(dir))
                } else if fileManager.isExecutableFile(atPath: dir.resolvingSymlinksInPath().relativePath) {
                    list.append(dir)
                }
            }
        } catch {
            NSLog("Error on getAppList: %@", error.localizedDescription)
        }
        return list
    }

    func get() -> [ListItem] {
        appList.map({ elem in
            return ListItem(name: elem.lastPathComponent, data: elem)
        })
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

    func getContentsOfPathFiles(filepath: String) -> [String] {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        var filelist: [String] = []

        fileManager.fileExists(atPath: filepath, isDirectory: &isDir)

        if isDir.boolValue {
            do {
                let files = try fileManager.contentsOfDirectory(atPath: filepath)
                for file in files {
                    let content = fileManager.contents(
                        atPath: filepath + file)!
                    let str = String(decoding: content, as: UTF8.self)
                    let folders = str.components(separatedBy: "\n")
                    filelist.append(contentsOf: folders)
                }
            } catch {
                    NSLog("Error on getContentsOfPathFiles: %@", error.localizedDescription)
            }
        } else {
            let content = fileManager.contents(
                atPath: filepath)!
            let str = String(decoding: content, as: UTF8.self)
            let folders = str.components(separatedBy: "\n")
            filelist.append(contentsOf: folders)
        }
        return filelist
    }
}
