# recordbase

RecordBase API and Client

Client
```
rb := recordbase.NewClient(context.Background(), "multi://127.0.0.1:5555,127.0.0.1:7777", MY_API_KEY, optTlsConfig)
defer rb.Destroy()
```

