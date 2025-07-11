//
//  ShieldConfigurationExtension.swift
//  shieldUI
//
//  Created by CJ Balmaceda on 7/11/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    let store = ManagedSettingsStore()
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield as needed for applications.
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "hourglass")?.withTintColor(.white),
            title: ShieldConfiguration.Label(
                text: "Are you really doing this right now?",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Go touch Grass",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: .systemGray3
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for applications shielded because of their category.
        ShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        ShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        ShieldConfiguration()
    }
}
