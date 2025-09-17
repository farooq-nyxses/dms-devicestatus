package com.example.devicestatus.repo;

import com.example.devicestatus.model.DeviceStatus;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceStatusRepository extends JpaRepository<DeviceStatus, Integer> {
}
