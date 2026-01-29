-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 29, 2026 at 04:07 PM
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
-- Database: `aplikasi_movie_collection`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddMovie` (IN `p_user_id` INT, IN `p_title` VARCHAR(200), IN `p_year` VARCHAR(10), IN `p_genre` VARCHAR(100), IN `p_director` VARCHAR(100), IN `p_duration` VARCHAR(20), IN `p_poster_url` TEXT, IN `p_description` TEXT, IN `p_watch_status` ENUM('plan_to_watch','watching','watched'), IN `p_is_favorite` TINYINT)   BEGIN
    INSERT INTO movies (
        user_id, title, year, genre, director, duration, 
        poster_url, description, watch_status, is_favorite
    ) VALUES (
        p_user_id, p_title, p_year, p_genre, p_director, p_duration,
        p_poster_url, p_description, p_watch_status, p_is_favorite
    );
    
    SELECT LAST_INSERT_ID() AS movie_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ToggleFavorite` (IN `p_movie_id` INT, IN `p_is_favorite` TINYINT)   BEGIN
    UPDATE movies 
    SET is_favorite = p_is_favorite, updated_at = CURRENT_TIMESTAMP
    WHERE id = p_movie_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `movies`
--

CREATE TABLE `movies` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `year` varchar(10) NOT NULL,
  `genre` varchar(100) NOT NULL,
  `director` varchar(100) NOT NULL,
  `duration` varchar(20) NOT NULL,
  `poster_url` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `watch_status` enum('plan_to_watch','watching','watched') DEFAULT 'plan_to_watch',
  `is_favorite` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `movies`
--

INSERT INTO `movies` (`id`, `user_id`, `title`, `year`, `genre`, `director`, `duration`, `poster_url`, `description`, `watch_status`, `is_favorite`, `created_at`, `updated_at`) VALUES
(3, 2, 'Parasite', '2019', 'Comedy, Drama, Thriller', 'Bong Joon Ho', '132 min', 'https://m.media-amazon.com/images/M/MV5BYWZjMjk3ZTItODQ2ZC00NTY5LWE0ZDYtZTI3MjcwN2Q5NTVkXkEyXkFqcGdeQXVyODk4OTc3MTY@._V1_FMjpg_UX1000_.jpg', 'A poor family schemes to become employed by a wealthy family.', 'watching', 0, '2026-01-23 12:24:41', '2026-01-23 12:24:41'),
(4, 3, 'Spirited Away', '2001', 'Animation, Adventure, Family', 'Hayao Miyazaki', '125 min', 'https://m.media-amazon.com/images/M/MV5BMjlmZmI5MDctNDE2YS00YWE0LWE5ZWItZDBhYWQ0NTcxNWRhXkEyXkFqcGdeQXVyMTMxODk2OTU@._V1_FMjpg_UX1000_.jpg', 'A young girl wanders into a world ruled by gods, witches, and spirits.', 'plan_to_watch', 1, '2026-01-23 12:24:41', '2026-01-23 12:24:41');

--
-- Triggers `movies`
--
DELIMITER $$
CREATE TRIGGER `before_movie_update` BEFORE UPDATE ON `movies` FOR EACH ROW BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `movie_id` int(11) NOT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` >= 1 and `rating` <= 5),
  `comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `user_id`, `movie_id`, `rating`, `comment`, `created_at`) VALUES
(4, 3, 3, 5, 'Masterpiece! The social commentary is sharp and the storytelling is flawless.', '2026-01-23 12:24:41'),
(5, 2, 4, 5, 'Beautiful animation and touching story. A true work of art.', '2026-01-23 12:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `email`, `full_name`, `created_at`, `updated_at`) VALUES
(2, 'jane_smith', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'jane@example.com', 'Jane Smith', '2026-01-23 12:24:41', '2026-01-23 12:24:41'),
(3, 'bob_wilson', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'bob@example.com', 'Bob Wilson', '2026-01-23 12:24:41', '2026-01-23 12:24:41'),
(4, 'sandi', '$2y$10$', 'yudhasandi_483@gmail.com', 'Sandi Yudha', '2026-01-23 12:43:12', '2026-01-23 12:46:06');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `movies`
--
ALTER TABLE `movies`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_movies_user_id` (`user_id`),
  ADD KEY `idx_movies_watch_status` (`watch_status`),
  ADD KEY `idx_movies_is_favorite` (`is_favorite`),
  ADD KEY `idx_movies_created_at` (`created_at`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reviews_movie_id` (`movie_id`),
  ADD KEY `idx_reviews_user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `movies`
--
ALTER TABLE `movies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `movies`
--
ALTER TABLE `movies`
  ADD CONSTRAINT `movies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`movie_id`) REFERENCES `movies` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
