package com.example.devicestatus.web;

import com.example.devicestatus.model.DeviceStatus;
import com.example.devicestatus.repo.DeviceStatusRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/devicestatuses")
public class DeviceStatusController {

    private final DeviceStatusRepository repo;

    public DeviceStatusController(DeviceStatusRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<DeviceStatus> getAll() {
        return repo.findAll();
    }

    @GetMapping("/{deviceId}")
    public ResponseEntity<DeviceStatus> getOne(@PathVariable("deviceId") Integer deviceId) {
        return repo.findById(deviceId)
                   .map(ResponseEntity::ok)
                   .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
