//
//  FocusDetectiveApp.swift
//  FocusDetective
//
//  Created by Mike Piontek on 9/3/24.
//

import SwiftUI
@preconcurrency import AppKit

@main
struct FocusDetectiveApp: App {

	@State var observer = FocusObserver()

	var body: some Scene {

		WindowGroup {

			List {

				Text("The most recent application is shown at the top. You can close this window or hide the application, and Focus Detective will continue to detect changes in the background.")
					.font(.callout)
					.padding(.bottom, 4)

				Toggle("Only show non-click focus changes", isOn: $observer.filterClickInitiated)
					.padding(.bottom, 8)

				ForEach(observer.filteredChanges) { change in
					HStack(alignment: .firstTextBaseline) {
						Text(change.date.formatted(.dateTime.hour().minute().second(.twoDigits)))
							.font(.callout)
							.monospacedDigit()
							.frame(width: 90, alignment: .leading)
							.accessibilityLabel("Time: \(change.date.formatted(.dateTime.hour().minute().second(.twoDigits)))")
						Text(verbatim: change.name)
							.font(.headline)
							.accessibilityLabel("Application: \(change.name)")
					}
					.padding(.vertical, 4)
					.accessibilityElement(children: .combine)
				}

			}
			.frame(minWidth: 380)
			.navigationTitle("Focus Detective")
			.toolbar {
				Button("Open Console", systemImage: "list.bullet.rectangle") {
					openConsoleApp()
				}
				.accessibilityHint("Opens the Console application to view system logs")
			}

		}
		.defaultSize(width: 380, height: 380)
		.defaultPosition(.center)
		.commands {
			CommandGroup(replacing: .appInfo) {
				Button("About Focus Detective") {
					NSApplication.shared.orderFrontStandardAboutPanel()
				}
			}
		}

	}

	private func openConsoleApp() {
		let workspace = NSWorkspace.shared
		guard let url = workspace.urlForApplication(withBundleIdentifier: "com.apple.Console") else {
			print("Console application not found")
			return
		}

		NSWorkspace.shared.openApplication(at: url, configuration: .init())
	}

}

@Observable
@MainActor
class FocusObserver {

	var changes: [FocusChange] = []
	var filterClickInitiated: Bool = false

	@ObservationIgnored
	nonisolated(unsafe) private var observer: NSObjectProtocol?
	@ObservationIgnored
	nonisolated(unsafe) private var lastClickTime: Date?

	var filteredChanges: [FocusChange] {
		if filterClickInitiated {
			return changes.filter { !$0.wasClickInitiated }
		} else {
			return changes
		}
	}

	init() {
		filterClickInitiated = UserDefaults.standard.bool(forKey: "filterClickInitiated")
		setupMouseMonitoring()
		setupFocusObserver()
	}

	private func setupMouseMonitoring() {
		var lastMouseLocation = NSEvent.mouseLocation
		Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
			let currentLocation = NSEvent.mouseLocation
			let distance = sqrt(pow(currentLocation.x - lastMouseLocation.x, 2) +
							   pow(currentLocation.y - lastMouseLocation.y, 2))
			if distance > 5.0 {
				self?.lastClickTime = Date.now
				lastMouseLocation = currentLocation
			}
		}
	}

	func toggleFilter() {
		filterClickInitiated.toggle()
		UserDefaults.standard.set(filterClickInitiated, forKey: "filterClickInitiated")
	}

	private func setupFocusObserver() {
		let center = NSWorkspace.shared.notificationCenter
		observer = center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
			object: nil, queue: nil) { [weak self] notification in
			let date = Date.now
			let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
			let name = app?.localizedName ?? "Unknown"

			let wasClickInitiated = self?.lastClickTime.map { clickTime in
				date.timeIntervalSince(clickTime) < 0.5
			} ?? false

			let change = FocusChange(date: date, name: name, wasClickInitiated: wasClickInitiated)
			Task { @MainActor in
				self?.changes.insert(change, at: 0)
			}
		}
	}

	deinit {
		if let observer = observer {
			NSWorkspace.shared.notificationCenter.removeObserver(observer)
		}
	}

}

struct FocusChange: Identifiable {
	let id = UUID()
	let date: Date
	let name: String
	let wasClickInitiated: Bool
}
