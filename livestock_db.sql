-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 01, 2025 at 06:19 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `livestock_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `batas_air`
--

CREATE TABLE `batas_air` (
  `id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `batas_atas` float NOT NULL,
  `batas_bawah` float NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `batas_air`
--

INSERT INTO `batas_air` (`id`, `device_id`, `batas_atas`, `batas_bawah`, `updated_at`) VALUES
(1, 1, 200, 100, '2025-06-28 14:57:16');

-- --------------------------------------------------------

--
-- Table structure for table `manual_pump_logs`
--

CREATE TABLE `manual_pump_logs` (
  `id` int(11) NOT NULL,
  `level_air` varchar(10) DEFAULT NULL,
  `batas_ketinggian` varchar(10) DEFAULT NULL,
  `batas_rendah` varchar(10) DEFAULT NULL,
  `waktu_konfirmasi` timestamp NOT NULL DEFAULT current_timestamp(),
  `status_pompa` enum('on','off') DEFAULT 'off'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `manual_pump_logs`
--

INSERT INTO `manual_pump_logs` (`id`, `level_air`, `batas_ketinggian`, `batas_rendah`, `waktu_konfirmasi`, `status_pompa`) VALUES
(1, 'N/A', 'N/A', 'N/A', '2025-06-28 10:25:06', 'off'),
(2, 'N/A', 'N/A', 'N/A', '2025-06-28 10:25:07', 'on'),
(3, '...', '20cm', '100cm', '2025-06-28 10:25:10', 'on'),
(4, '...', '20cm', '100cm', '2025-06-28 10:25:13', 'on'),
(5, '...', '20cm', '100cm', '2025-06-28 10:25:14', 'on'),
(6, '...', '20cm', '100cm', '2025-06-28 10:25:15', 'on'),
(7, '...', '20cm', '100cm', '2025-06-28 10:25:15', 'on'),
(8, '...', '20cm', '100cm', '2025-06-28 10:25:16', 'on'),
(9, 'N/A', 'N/A', 'N/A', '2025-06-28 12:03:48', 'off'),
(10, 'N/A', 'N/A', 'N/A', '2025-06-28 12:03:50', 'on'),
(11, 'N/A', 'N/A', 'N/A', '2025-06-28 14:50:29', 'off'),
(12, 'N/A', 'N/A', 'N/A', '2025-06-28 14:50:32', 'on'),
(13, 'N/A', 'N/A', 'N/A', '2025-06-28 14:51:13', 'off'),
(14, 'N/A', 'N/A', 'N/A', '2025-06-28 14:51:19', 'on'),
(15, 'N/A', 'N/A', 'N/A', '2025-06-28 14:51:21', 'off'),
(16, 'N/A', 'N/A', 'N/A', '2025-06-28 14:52:56', 'on'),
(17, '...', '20cm', '100cm', '2025-06-28 14:53:16', 'on'),
(18, 'N/A', 'N/A', 'N/A', '2025-06-28 14:53:24', 'off'),
(19, '...', '20cm', '100cm', '2025-06-28 14:53:26', 'off'),
(20, '...', '20cm', '100cm', '2025-06-28 14:53:29', 'off'),
(21, 'N/A', 'N/A', 'N/A', '2025-06-28 14:55:46', 'on'),
(22, 'N/A', 'N/A', 'N/A', '2025-06-28 14:55:48', 'off'),
(23, 'N/A', 'N/A', 'N/A', '2025-06-28 14:55:49', 'on'),
(24, 'N/A', 'N/A', 'N/A', '2025-06-28 14:55:50', 'off'),
(25, '...', '20cm', '100cm', '2025-06-28 14:58:33', 'off'),
(26, 'N/A', 'N/A', 'N/A', '2025-06-28 14:58:41', 'on'),
(27, 'N/A', 'N/A', 'N/A', '2025-06-28 14:58:51', 'off'),
(28, '...', '20cm', '100cm', '2025-06-28 15:02:02', 'off'),
(29, '...', '20cm', '100cm', '2025-06-28 15:19:02', 'off'),
(30, 'N/A', 'N/A', 'N/A', '2025-06-28 15:19:08', 'on'),
(31, 'N/A', 'N/A', 'N/A', '2025-06-28 15:19:10', 'off'),
(32, 'N/A', 'N/A', 'N/A', '2025-06-28 15:19:12', 'on'),
(33, 'N/A', 'N/A', 'N/A', '2025-06-28 15:19:13', 'off'),
(34, 'N/A', 'N/A', 'N/A', '2025-06-28 15:19:15', 'on');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `title` varchar(100) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `type` enum('suhu','level_air') DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_read` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `title`, `message`, `type`, `created_at`, `is_read`) VALUES
(4, 'Notifikasi Suhu', 'Peringatan Suhu terlalu tinggi, harap perhatikan pemberian air ternak!', 'suhu', '2025-06-25 08:00:43', 1),
(5, 'Notifikasi Level Air', 'Level air terlalu rendah, harap segera isi ulang tangki untuk menjaga ketersediaan air!', 'level_air', '2025-06-25 08:04:19', 1),
(6, 'Notifikasi Level Air', 'Level air terlalu tinggi, periksa kemungkinan kebocoran atau overflow pada tangki!', 'level_air', '2025-06-25 08:04:27', 1);

-- --------------------------------------------------------

--
-- Table structure for table `pump_status`
--

CREATE TABLE `pump_status` (
  `id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `mode` enum('auto','manual') DEFAULT 'auto',
  `status` enum('on','off') NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pump_status`
--

INSERT INTO `pump_status` (`id`, `device_id`, `mode`, `status`, `created_at`) VALUES
(1, 1, 'auto', 'on', '2025-06-16 07:17:12');

-- --------------------------------------------------------

--
-- Table structure for table `temperature_logs`
--

CREATE TABLE `temperature_logs` (
  `id` int(11) NOT NULL,
  `device_id` int(11) DEFAULT NULL,
  `temperature` float DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `temperature_logs`
--

INSERT INTO `temperature_logs` (`id`, `device_id`, `temperature`, `status`, `note`, `created_at`) VALUES
(1, 1, 32.7, 'Normal', 'Suhu dalam batas normal', '2025-06-15 20:53:45');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `createdAt` datetime DEFAULT current_timestamp(),
  `updatedAt` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `role` varchar(255) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL,
  `profile_image` varchar(255) DEFAULT NULL,
  `status` enum('pending','active','inactive') NOT NULL DEFAULT 'pending',
  `created_by_admin` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `createdAt`, `updatedAt`, `role`, `username`, `profile_image`, `status`, `created_by_admin`) VALUES
(1, 'Admin Test', 'admintest@gmail.com', '$2b$10$L6rgSueZb5Hk6uF7a63IOO5tUk2Kl2BZQih.eNVEphz2VOEDrpuJ.', '2025-06-11 03:34:41', '2025-06-22 12:32:35', 'admin', 'admintest', NULL, 'active', NULL),
(4, 'User Test', 'usertest@gmail.com', '$2b$10$LRHmaGXz7DX/0.NfZ7DfpOlop1Kj5ql6RQWkPC1QAGA0MWT5xVny2', '2025-06-26 17:04:45', '2025-06-26 17:05:58', 'user', 'usertest', NULL, 'active', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `water_levels`
--

CREATE TABLE `water_levels` (
  `id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `level_percentage` float NOT NULL,
  `status` varchar(20) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `water_levels`
--

INSERT INTO `water_levels` (`id`, `device_id`, `level_percentage`, `status`, `note`, `created_at`) VALUES
(1, 1, 28.5, 'Rendah', 'Peringatan: Level air rendah, isi manual atau aktifkan pompa!', '2025-06-16 07:17:12');

-- --------------------------------------------------------

--
-- Table structure for table `water_usages`
--

CREATE TABLE `water_usages` (
  `id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `usage_ml` float NOT NULL,
  `date` date DEFAULT curdate(),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `water_usages`
--

INSERT INTO `water_usages` (`id`, `device_id`, `usage_ml`, `date`, `created_at`) VALUES
(1, 1, 30500.8, '2025-06-27', '2025-06-27 12:50:02');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `batas_air`
--
ALTER TABLE `batas_air`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `manual_pump_logs`
--
ALTER TABLE `manual_pump_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pump_status`
--
ALTER TABLE `pump_status`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `temperature_logs`
--
ALTER TABLE `temperature_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `fk_created_by_admin` (`created_by_admin`);

--
-- Indexes for table `water_levels`
--
ALTER TABLE `water_levels`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `water_usages`
--
ALTER TABLE `water_usages`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `batas_air`
--
ALTER TABLE `batas_air`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `manual_pump_logs`
--
ALTER TABLE `manual_pump_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `pump_status`
--
ALTER TABLE `pump_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `temperature_logs`
--
ALTER TABLE `temperature_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `water_levels`
--
ALTER TABLE `water_levels`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `water_usages`
--
ALTER TABLE `water_usages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_created_by_admin` FOREIGN KEY (`created_by_admin`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
