# Lab Solution

There's a sample solution in the lab folder: `lab/uptime-dashboard.json`. You can load that into Grafana from **Dashboards > New > Import**.

### Infrastructure row

Click _Add_ in the top menu and select _Row_. 

Hover over the row name and a gear icon appears - click it to set the row name to _Infrastructure_.

Hover over your original status table, open the panel menu (the three dots) and select _Edit_.

Add a label to the PromQL:

```
sum without(job, tier) (up{tier="infrastructure"})
```

Click _Back_ - and do the same for the timeline panel (both can use the same query).

### Backend row

Add a new row for _Backend_.

Hover over the status table, open the panel menu (three dots) and select _More... > Duplicate_.

Edit the label selector in the new panel to use this PromQL:

```
sum without(job, tier) (up{tier="backend"})
```

Duplicate the timeline panel too, and set the PromQL to the same to filter for the backend tier.

### Web row

Repeat the steps from the backend row for the web tier.

### Save the dashboard

You can drag the panels into the correct rows and resize them. Click _Save dashboard_ in the top right to save it.

Use _Export > Export as JSON_ (next to the dashboard title) to save the JSON to a file.

___
> Back to the [exercises](README.md).
