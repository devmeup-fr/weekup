String getAuthUsernameMaintainerMock() => 'testapi';
String getAuthPassMaintainerMock() => 's.gailhou';

Map<String, dynamic> getAuthMaintainerMock() => {
      "user": {"id": 1159, "right": 6, "label": "testmobile"},
      "customer": {"id": 51, "label": "Zone 52"},
      "modules": [
        {"module_SN": "P3B0F5432", "firm_actuel": "1.2.4", "boot_actuel": null},
        {"module_SN": "P32005A35", "firm_actuel": "1.2.2", "boot_actuel": null},
        {
          "module_SN": "P35004937",
          "firm_actuel": "1.2.5",
          "boot_actuel": "1.0"
        },
        {
          "module_SN": "P23230015",
          "firm_actuel": "1.2.3",
          "boot_actuel": "1.3"
        },
        {
          "module_SN": "P23240006",
          "firm_actuel": "1.2.4",
          "boot_actuel": "1.3"
        },
        {"module_SN": "P23240009", "firm_actuel": "1.2.2", "boot_actuel": null},
        {"module_SN": "P23240005", "firm_actuel": "1.2.4", "boot_actuel": null},
        {
          "module_SN": "P23500004",
          "firm_actuel": "1.2.4",
          "boot_actuel": "1.3"
        },
        {"module_SN": "P260F4D3B", "firm_actuel": "1.2.4", "boot_actuel": null},
        {"module_SN": "P23240010", "firm_actuel": "1.2.4", "boot_actuel": null},
        {"module_SN": "P23120194", "firm_actuel": "1.2.4", "boot_actuel": null},
        {"module_SN": "P23130056", "firm_actuel": "1.2.4", "boot_actuel": null},
        {"module_SN": "P23130059", "firm_actuel": "1.2.4", "boot_actuel": "1.0"}
      ],
      "bin": {"id": "14", "firm": "1.2.4", "boot": "1.3"}
    };

List<String> getSerialAvailableMaintainerMock() => [
      "P3B0F5432",
      "P32005A35",
      "P35004937",
      "P23230015",
      "P23240006",
      "P23240009",
      "P23240005",
      "P23500004",
      "P260F4D3B",
      "P23120194",
      "P23130056",
      "P23130059"
    ];
