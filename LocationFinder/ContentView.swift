//
//  ContentView.swift
//  LocationFinder
//
//  Created by sabbir_iosdev on 22/4/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            SearchView()
                .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
